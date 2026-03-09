#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'fileutils'
require 'time'
require 'open3'
require 'timeout'
require 'shellwords'

BASE_DIR = File.expand_path(__dir__)
WORK_DIR = File.join(BASE_DIR, 'generated-conf')
RESULTS_DIR = File.join(BASE_DIR, 'results-conf')
LOGS_DIR    = File.join(BASE_DIR, 'logs-conf')

GO_DIR = File.join(Dir.home, '.local', 'go')
NPM_PREFIX = File.join(Dir.home, '.local', 'npm')
ALMIDE_DIR = ENV['ALMIDE_DIR'] || File.join(Dir.home, '.local', 'almide')

LANGUAGES = {
  'python'      => { exts: %w[py],     version_cmd: 'python3 --version' },
  'go'          => { exts: %w[go],     version_cmd: "#{GO_DIR}/bin/go version" },
  'almide'      => { exts: %w[almd],   version_cmd: 'almide --version 2>&1 || echo "almide (local)"',
                     extra_files: %w[CLAUDE.md build-conf.sh],
                     rename_files: { 'build-conf.sh' => 'build.sh' },
                     extra_prompt: 'Write Almide code. CLAUDE.md has the complete language reference and all stdlib signatures. ' \
                                   'Write miniconf.almd, then bash build.sh && bash test-conf-v1.sh' },
}

TRIALS = 3

# ---------------------------------------------------------------------------
# CLI args
# ---------------------------------------------------------------------------

selected_languages = nil
selected_trials = TRIALS
selected_start = 1
dry_run = false
v1_only = false

i = 0
while i < ARGV.length
  case ARGV[i]
  when '--lang', '-l'
    selected_languages = ARGV[i + 1].split(',').map(&:strip)
    i += 2
  when '--trials', '-t'
    selected_trials = ARGV[i + 1].to_i
    i += 2
  when '--start', '-s'
    selected_start = ARGV[i + 1].to_i
    i += 2
  when '--dry-run'
    dry_run = true
    i += 1
  when '--v1-only'
    v1_only = true
    i += 1
  else
    i += 1
  end
end

languages_to_run = selected_languages || LANGUAGES.keys

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def run_cmd(cmd, dir: nil, timeout: 600)
  opts = {}
  opts[:chdir] = dir if dir
  stdin_r, stdout_r, stderr_r, wait_thr = Open3.popen3(cmd, **opts)
  stdin_r.close
  stdout_r.set_encoding('UTF-8')
  stderr_r.set_encoding('UTF-8')
  stdout = stderr = ''
  begin
    Timeout.timeout(timeout) do
      stdout = stdout_r.read
      stderr = stderr_r.read
    end
  rescue Timeout::Error
    Process.kill('TERM', wait_thr.pid) rescue nil
    stdout = stdout_r.read rescue ''
    stderr = "Timeout after #{timeout}s"
  end
  stdout_r.close
  stderr_r.close
  status = wait_thr.value
  { stdout: stdout, stderr: stderr, exit_code: status.exitstatus, success: status.success? }
end

def extra_path
  "#{ALMIDE_DIR}:#{GO_DIR}/bin:#{NPM_PREFIX}/bin"
end

def get_version(lang)
  config = LANGUAGES[lang]
  cmd = "export PATH=#{extra_path}:$PATH && #{config[:version_cmd]}"
  result = run_cmd(cmd)
  if result[:success]
    (result[:stdout].strip.empty? ? result[:stderr].strip : result[:stdout].strip).lines.first&.strip || 'unknown'
  else
    'not installed'
  end
end

def count_loc(dir, lang)
  config = LANGUAGES[lang]
  exts = config[:exts]
  files = exts.flat_map { |e| Dir.glob(File.join(dir, '**', "*.#{e}")) }
  files.reject! { |f| f.include?('/node_modules/') || f.include?('/target/') }

  miniconf = File.join(dir, 'miniconf')
  if File.exist?(miniconf) && !files.include?(miniconf)
    begin
      content = File.read(miniconf, encoding: 'UTF-8')
      files << miniconf if content.valid_encoding?
    rescue StandardError
    end
  end

  files.sum do |f|
    begin
      File.readlines(f).count { |l| !l.strip.empty? }
    rescue StandardError
      0
    end
  end
end

def parse_claude_output(raw_output)
  raw_output = raw_output.dup.force_encoding('UTF-8')
  events = JSON.parse(raw_output.strip)
  events = [events] unless events.is_a?(Array)
  result_event = events.reverse.find { |e| e.is_a?(Hash) && e['type'] == 'result' }
  return nil unless result_event

  usage = result_event['usage'] || {}
  {
    input_tokens: usage['input_tokens'] || 0,
    output_tokens: usage['output_tokens'] || 0,
    cache_creation_tokens: usage['cache_creation_input_tokens'] || 0,
    cache_read_tokens: usage['cache_read_input_tokens'] || 0,
    cost_usd: result_event['total_cost_usd'] || 0.0,
    num_turns: result_event['num_turns'] || 0,
    duration_ms: result_event['duration_ms'] || 0,
  }
rescue JSON::ParserError => e
  puts "  WARNING: Failed to parse Claude JSON output: #{e.message}"
  nil
end

def run_claude(prompt, dir:, log_path: nil)
  env_prefix = "unset CLAUDECODE && export PATH=#{extra_path}:$PATH && "
  cmd = "#{env_prefix}claude -p #{Shellwords.escape(prompt)} --dangerously-skip-permissions --output-format json"

  puts "  Running Claude..."
  start_time = Time.now
  result = run_cmd(cmd, dir: dir, timeout: 1200)
  elapsed = Time.now - start_time

  if log_path
    FileUtils.mkdir_p(File.dirname(log_path))
    File.write(log_path, result[:stdout])
    puts "  Log saved to #{log_path}"
  end

  {
    stdout: result[:stdout],
    stderr: result[:stderr],
    success: result[:success],
    elapsed_seconds: elapsed.round(1),
    claude_data: parse_claude_output(result[:stdout]),
  }
end

def run_tests(test_script, dir:)
  cmd = "export PATH=#{extra_path}:$PATH && bash #{test_script}"
  result = run_cmd(cmd, dir: dir, timeout: 120)

  output = result[:stdout] + result[:stderr]
  passed = output[/PASSED:\s*(\d+)/, 1]&.to_i || 0
  failed = output[/FAILED:\s*(\d+)/, 1]&.to_i || 0

  {
    success: result[:success],
    passed: passed,
    failed: failed,
    total: passed + failed,
    output: output,
  }
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

puts '=' * 60
puts 'Claude Code MiniConf Benchmark'
puts '=' * 60
puts

claude_version_result = run_cmd('claude --version 2>/dev/null || echo unknown')
claude_version = claude_version_result[:stdout].strip

puts "Claude Version: #{claude_version}"
puts "Languages: #{languages_to_run.join(', ')}"
puts "Trials: #{selected_start}..#{selected_start + selected_trials - 1} (#{selected_trials} trials)"
puts "Dry run: #{dry_run}"
puts

# Language versions
puts '--- Language Versions ---'
versions = {}
languages_to_run.each do |lang|
  versions[lang] = get_version(lang)
  puts "  #{lang}: #{versions[lang]}"
end
puts

FileUtils.mkdir_p(WORK_DIR)
FileUtils.mkdir_p(RESULTS_DIR)

# Warmup
unless dry_run
  puts '--- Warmup ---'
  warmup_dir = File.join(WORK_DIR, '.warmup')
  FileUtils.mkdir_p(warmup_dir)
  warmup_result = run_claude('Respond with just the word OK.', dir: warmup_dir)
  puts "  Warmup done in #{warmup_result[:elapsed_seconds]}s (success=#{warmup_result[:success]})"
  FileUtils.rm_rf(warmup_dir)
  puts
end

results = []

selected_trials.times do |trial_idx|
  trial = selected_start + trial_idx
  languages_to_run.each do |lang|
    puts '=' * 60
    puts "Trial #{trial} (#{trial_idx + 1}/#{selected_trials}) - #{lang}"
    puts '=' * 60

    dir_name = lang.tr('/', '-')
    v1_dir = File.join(WORK_DIR, "miniconf-#{dir_name}-#{trial}-v1")
    v2_dir = File.join(WORK_DIR, "miniconf-#{dir_name}-#{trial}-v2")
    FileUtils.rm_rf(v1_dir)
    FileUtils.rm_rf(v2_dir)
    FileUtils.mkdir_p(v1_dir)

    record = {
      language: lang, trial: trial, v1_dir: v1_dir, v2_dir: v2_dir,
      v1_time: nil, v1_pass: false, v1_passed_count: 0, v1_failed_count: 0, v1_total_count: 0, v1_loc: 0,
      v2_time: nil, v2_pass: false, v2_passed_count: 0, v2_failed_count: 0, v2_total_count: 0, v2_loc: 0,
      v1_claude: nil, v2_claude: nil,
    }

    # --- Phase 1: v1 ---
    puts "\n--- Phase 1: v1 ---"
    FileUtils.cp(File.join(BASE_DIR, 'SPEC-conf-v1.txt'), v1_dir)
    FileUtils.cp(File.join(BASE_DIR, 'test-conf-v1.sh'), v1_dir)
    (LANGUAGES[lang][:extra_files] || []).each do |f|
      dest_name = (LANGUAGES[lang][:rename_files] || {})[f] || f
      FileUtils.cp(File.join(BASE_DIR, f), File.join(v1_dir, dest_name))
    end

    v1_prompt = "Implement miniconf as described in SPEC-conf-v1.txt using #{lang.capitalize}. " \
                "The executable must be named 'miniconf' and be runnable as ./miniconf. " \
                "For compiled languages, include a Makefile or build script. " \
                "For interpreted languages, ensure the miniconf file has a proper shebang line and is executable. " \
                "Verify your implementation passes all tests by running: bash test-conf-v1.sh"
    v1_prompt += " #{LANGUAGES[lang][:extra_prompt]}" if LANGUAGES[lang][:extra_prompt]

    if dry_run
      puts "  [DRY RUN] Would run Claude with prompt for v1 #{lang}"
      record[:v1_time] = 0
    else
      v1_log = File.join(LOGS_DIR, "miniconf-#{dir_name}-#{trial}-v1.json")
      v1_result = run_claude(v1_prompt, dir: v1_dir, log_path: v1_log)
      record[:v1_time] = v1_result[:elapsed_seconds]
      record[:v1_claude] = v1_result[:claude_data]
      puts "  Claude finished in #{v1_result[:elapsed_seconds]}s (success=#{v1_result[:success]})"

      puts '  Running v1 tests...'
      test_result = run_tests('test-conf-v1.sh', dir: v1_dir)
      record[:v1_pass] = test_result[:success]
      record[:v1_passed_count] = test_result[:passed]
      record[:v1_failed_count] = test_result[:failed]
      record[:v1_total_count] = test_result[:total]
      puts "  Tests: #{test_result[:passed]}/#{test_result[:total]} passed (#{test_result[:success] ? 'PASS' : 'FAIL'})"

      record[:v1_loc] = count_loc(v1_dir, lang)
      puts "  LOC: #{record[:v1_loc]}"
    end

    # --- Phase 2: v2 ---
    unless v1_only
    puts "\n--- Phase 2: v2 ---"
    FileUtils.cp_r(v1_dir, v2_dir)
    FileUtils.cp(File.join(BASE_DIR, 'SPEC-conf-v2.txt'), v2_dir)
    FileUtils.cp(File.join(BASE_DIR, 'test-conf-v2.sh'), v2_dir)

    v2_prompt = "Read SPEC-conf-v2.txt and extend the existing miniconf implementation " \
                "with set, merge, diff commands, and extended validation (range, min_len, max_len). " \
                "Verify your implementation passes all tests by running: bash test-conf-v2.sh"
    v2_prompt += " #{LANGUAGES[lang][:extra_prompt]}" if LANGUAGES[lang][:extra_prompt]

    if dry_run
      puts "  [DRY RUN] Would run Claude with prompt for v2 #{lang}"
      record[:v2_time] = 0
    else
      v2_log = File.join(LOGS_DIR, "miniconf-#{dir_name}-#{trial}-v2.json")
      v2_result = run_claude(v2_prompt, dir: v2_dir, log_path: v2_log)
      record[:v2_time] = v2_result[:elapsed_seconds]
      record[:v2_claude] = v2_result[:claude_data]
      puts "  Claude finished in #{v2_result[:elapsed_seconds]}s (success=#{v2_result[:success]})"

      puts '  Running v2 tests...'
      test_result = run_tests('test-conf-v2.sh', dir: v2_dir)
      record[:v2_pass] = test_result[:success]
      record[:v2_passed_count] = test_result[:passed]
      record[:v2_failed_count] = test_result[:failed]
      record[:v2_total_count] = test_result[:total]
      puts "  Tests: #{test_result[:passed]}/#{test_result[:total]} passed (#{test_result[:success] ? 'PASS' : 'FAIL'})"

      record[:v2_loc] = count_loc(v2_dir, lang)
      puts "  LOC: #{record[:v2_loc]}"
    end
    end # unless v1_only

    results << record
    puts
  end
end

# ---------------------------------------------------------------------------
# Save results JSON
# ---------------------------------------------------------------------------

puts '=' * 60
puts 'Saving results...'
puts '=' * 60

meta = {
  date: Time.now.strftime('%Y-%m-%d %H:%M:%S'),
  claude_version: claude_version,
  trials: selected_trials,
  versions: versions,
  benchmark: 'miniconf',
}

File.write(File.join(RESULTS_DIR, 'meta.json'), JSON.pretty_generate(meta))

results_path = File.join(RESULTS_DIR, 'results.json')
existing = if File.exist?(results_path)
             JSON.parse(File.read(results_path)) rescue []
           else
             []
           end
all_results = existing + results.map { |r| r.transform_keys(&:to_s) }
File.write(results_path, JSON.pretty_generate(all_results))

puts "Results saved to #{RESULTS_DIR}/"

# ---------------------------------------------------------------------------
# Summary table
# ---------------------------------------------------------------------------

puts
puts '=' * 60
puts 'Summary'
puts '=' * 60

languages_to_run.each do |lang|
  lang_results = results.select { |r| r[:language] == lang }
  next if lang_results.empty?

  v1_times = lang_results.map { |r| r[:v1_time] }.compact
  v2_times = lang_results.map { |r| r[:v2_time] }.compact
  v1_pass = lang_results.count { |r| r[:v1_pass] }
  v2_pass = lang_results.count { |r| r[:v2_pass] }
  v2_locs = lang_results.map { |r| r[:v2_loc] }.reject(&:zero?)

  avg_v1 = v1_times.empty? ? 0 : (v1_times.sum / v1_times.size).round(1)
  avg_v2 = v2_times.empty? ? 0 : (v2_times.sum / v2_times.size).round(1)
  avg_loc = v2_locs.empty? ? 0 : (v2_locs.sum / v2_locs.size).round(0)

  v1_costs = lang_results.map { |r| r[:v1_claude]&.[](:cost_usd) }.compact
  v2_costs = lang_results.map { |r| r[:v2_claude]&.[](:cost_usd) }.compact
  avg_cost = ((v1_costs + v2_costs).sum / [1, v1_costs.size].max).round(2)

  puts "#{lang}:"
  puts "  v1: #{avg_v1}s avg, #{v1_pass}/#{lang_results.size} passed"
  puts "  v2: #{avg_v2}s avg, #{v2_pass}/#{lang_results.size} passed"
  puts "  Total: #{(avg_v1 + avg_v2).round(1)}s avg"
  puts "  LOC (v2): #{avg_loc} avg"
  puts "  Cost: $#{avg_cost} avg"
  puts
end
