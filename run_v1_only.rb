require 'json'
require 'fileutils'
require 'open3'
require 'timeout'
require 'shellwords'

BASE_DIR = File.expand_path(__dir__)
WORK_DIR = File.join(BASE_DIR, 'generated')
LOGS_DIR = File.join(BASE_DIR, 'logs')
ALMIDE_DIR = ENV['ALMIDE_DIR'] || File.join(Dir.home, '.local', 'almide')

def extra_path
  "#{ALMIDE_DIR}"
end

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

def parse_claude_output(raw_output)
  raw_output = raw_output.dup.force_encoding('UTF-8')
  events = JSON.parse(raw_output.strip)
  events = [events] unless events.is_a?(Array)
  result_event = events.reverse.find { |e| e.is_a?(Hash) && e['type'] == 'result' }
  return nil unless result_event
  usage = result_event['usage'] || {}
  {
    num_turns: result_event['num_turns'] || 0,
    duration_ms: result_event['duration_ms'] || 0,
    cost_usd: result_event['total_cost_usd'] || 0.0,
  }
rescue JSON::ParserError
  nil
end

trials = (ARGV[0] || 3).to_i
results = []

# Warmup
puts "Warmup..."
warmup_dir = File.join(WORK_DIR, '.warmup')
FileUtils.mkdir_p(warmup_dir)
env_prefix = "export PATH=#{extra_path}:$PATH && "
run_cmd("#{env_prefix}claude -p 'Respond with just OK.' --dangerously-skip-permissions --output-format json", dir: warmup_dir, timeout: 60)
FileUtils.rm_rf(warmup_dir)

trials.times do |i|
  trial = i + 1
  puts "\n#{'=' * 50}"
  puts "Trial #{trial}/#{trials}"
  puts '=' * 50

  dir = File.join(WORK_DIR, "almide-v1-#{trial}")
  FileUtils.rm_rf(dir)
  FileUtils.mkdir_p(dir)

  FileUtils.cp(File.join(BASE_DIR, 'SPEC-v1.txt'), dir)
  FileUtils.cp(File.join(BASE_DIR, 'test-v1.sh'), dir)
  FileUtils.cp(File.join(BASE_DIR, 'CLAUDE.md'), dir)
  FileUtils.cp(File.join(BASE_DIR, 'build.sh'), dir)

  prompt = "Write code in Almide (.almd). CLAUDE.md contains the full language reference and build instructions. " \
           "Write a single file minigit.almd, then run: bash build.sh. " \
           "Implement minigit as described in SPEC-v1.txt. " \
           "The executable must be named 'minigit' and be runnable as ./minigit. " \
           "Verify your implementation passes all tests by running: bash test-v1.sh"

  log_path = File.join(LOGS_DIR, "almide-v1-#{trial}.json")
  FileUtils.mkdir_p(LOGS_DIR)

  puts "  Running Claude..."
  start = Time.now
  result = run_cmd(
    "#{env_prefix}claude -p #{Shellwords.escape(prompt)} --dangerously-skip-permissions --output-format json",
    dir: dir, timeout: 600
  )
  elapsed = (Time.now - start).round(1)

  File.write(log_path, result[:stdout])
  claude_data = parse_claude_output(result[:stdout])

  # Run tests
  test_result = run_cmd("#{env_prefix}bash test-v1.sh", dir: dir, timeout: 120)
  test_out = test_result[:stdout] + test_result[:stderr]
  passed = test_out[/PASSED:\s*(\d+)/, 1]&.to_i || 0
  failed = test_out[/FAILED:\s*(\d+)/, 1]&.to_i || 0

  # Count LOC
  almd_files = Dir.glob(File.join(dir, '*.almd'))
  loc = almd_files.sum { |f| File.readlines(f).count { |l| !l.strip.empty? } rescue 0 }

  turns = claude_data&.[](:num_turns) || '?'
  cost = claude_data&.[](:cost_usd)&.round(2) || '?'

  puts "  Time: #{elapsed}s | Tests: #{passed}/#{passed + failed} | LOC: #{loc} | Turns: #{turns} | Cost: $#{cost}"
  results << { trial: trial, time: elapsed, passed: passed, failed: failed, loc: loc, turns: turns, cost: cost }
end

puts "\n#{'=' * 50}"
puts "Summary"
puts '=' * 50
results.each do |r|
  status = r[:failed] == 0 ? 'PASS' : 'FAIL'
  puts "  Trial #{r[:trial]}: #{r[:time]}s | #{r[:passed]}/#{r[:passed] + r[:failed]} #{status} | LOC: #{r[:loc]} | Turns: #{r[:turns]} | $#{r[:cost]}"
end
times = results.map { |r| r[:time] }
avg = (times.sum / times.size).round(1)
puts "  Average: #{avg}s"
