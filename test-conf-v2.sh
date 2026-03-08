#!/usr/bin/env bash
set -e

PASS_COUNT=0
FAIL_COUNT=0

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT+1))
}

pass() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT+1))
}

cleanup() {
  cd "$(dirname "$0")"
  rm -rf testdir
}

# Build if needed
cd "$(dirname "$0")"

if [ -f Makefile ] || [ -f makefile ]; then
  make -s 2>/dev/null || true
fi
if [ -f build.sh ]; then
  bash build.sh 2>/dev/null || true
fi
chmod +x miniconf 2>/dev/null || true

######################################
# Setup
######################################

cleanup
mkdir testdir
cd testdir

##############################################################################
#                           V1 TESTS (1-24)
##############################################################################

######################################
# Create shared test files
######################################

cat > valid.conf <<'EOF'
# A comment
[server]
host = "localhost"
port = 8080
debug = true
tags = ["web", "api"]

[database]
url = "postgres://localhost/mydb"
pool_size = 5
EOF

######################################
# Test 1: check valid config
######################################

OUTPUT=$(../miniconf check valid.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "check valid config"
else
  fail "check valid config (got: $OUTPUT)"
fi

######################################
# Test 2: check unterminated string
######################################

cat > bad_string.conf <<'EOF'
[server]
host = "localhost
port = 8080
EOF

OUTPUT=$(../miniconf check bad_string.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: line 2: unterminated string"; then
  pass "check unterminated string"
else
  fail "check unterminated string (got: $OUTPUT)"
fi

######################################
# Test 3: check invalid value
######################################

cat > bad_value.conf <<'EOF'
[server]
host = localhost
EOF

OUTPUT=$(../miniconf check bad_value.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: line 2: invalid value"; then
  pass "check invalid value"
else
  fail "check invalid value (got: $OUTPUT)"
fi

######################################
# Test 4: check key before section
######################################

cat > no_section.conf <<'EOF'
host = "localhost"
[server]
port = 8080
EOF

OUTPUT=$(../miniconf check no_section.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: line 1: expected section header"; then
  pass "check key before section"
else
  fail "check key before section (got: $OUTPUT)"
fi

######################################
# Test 5: check invalid section header
######################################

cat > bad_section.conf <<'EOF'
[]
host = "test"
EOF

OUTPUT=$(../miniconf check bad_section.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: line 1: invalid section header"; then
  pass "check invalid section header"
else
  fail "check invalid section header (got: $OUTPUT)"
fi

######################################
# Test 6: check duplicate key
######################################

cat > dup_key.conf <<'EOF'
[server]
host = "a"
host = "b"
EOF

OUTPUT=$(../miniconf check dup_key.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: line 3: duplicate key"; then
  pass "check duplicate key"
else
  fail "check duplicate key (got: $OUTPUT)"
fi

######################################
# Test 7: get string value
######################################

OUTPUT=$(../miniconf get valid.conf server.host 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = '"localhost"' ]; then
  pass "get string value"
else
  fail "get string value (got: $OUTPUT)"
fi

######################################
# Test 8: get int value
######################################

OUTPUT=$(../miniconf get valid.conf server.port 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = "8080" ]; then
  pass "get int value"
else
  fail "get int value (got: $OUTPUT)"
fi

######################################
# Test 9: get bool value
######################################

OUTPUT=$(../miniconf get valid.conf server.debug 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = "true" ]; then
  pass "get bool value"
else
  fail "get bool value (got: $OUTPUT)"
fi

######################################
# Test 10: get list value
######################################

OUTPUT=$(../miniconf get valid.conf server.tags 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = '["web", "api"]' ]; then
  pass "get list value"
else
  fail "get list value (got: $OUTPUT)"
fi

######################################
# Test 11: get nonexistent section
######################################

OUTPUT=$(../miniconf get valid.conf missing.host 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: section not found: missing"; then
  pass "get nonexistent section"
else
  fail "get nonexistent section (got: $OUTPUT)"
fi

######################################
# Test 12: get nonexistent key
######################################

OUTPUT=$(../miniconf get valid.conf server.missing 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: key not found: server.missing"; then
  pass "get nonexistent key"
else
  fail "get nonexistent key (got: $OUTPUT)"
fi

######################################
# Test 13: get file not found
######################################

OUTPUT=$(../miniconf get nonexistent.conf server.host 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: file not found: nonexistent.conf"; then
  pass "get file not found"
else
  fail "get file not found (got: $OUTPUT)"
fi

######################################
# Test 14: validate valid config
######################################

cat > schema1.conf <<'EOF'
[server]
host: string, required
port: int, required
debug: bool, optional
tags: list, optional
EOF

OUTPUT=$(../miniconf validate valid.conf --schema schema1.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "validate valid config"
else
  fail "validate valid config (got: $OUTPUT)"
fi

######################################
# Test 15: validate missing required field
######################################

cat > missing_field.conf <<'EOF'
[server]
host = "localhost"
EOF

cat > schema_strict.conf <<'EOF'
[server]
host: string, required
port: int, required
EOF

OUTPUT=$(../miniconf validate missing_field.conf --schema schema_strict.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[server\] port: required field missing'; then
  pass "validate missing required field"
else
  fail "validate missing required field (got: $OUTPUT)"
fi

######################################
# Test 16: validate type mismatch
######################################

cat > type_mismatch.conf <<'EOF'
[server]
host = "localhost"
port = "not_a_number"
EOF

OUTPUT=$(../miniconf validate type_mismatch.conf --schema schema_strict.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[server\] port: expected int, got string'; then
  pass "validate type mismatch"
else
  fail "validate type mismatch (got: $OUTPUT)"
fi

######################################
# Test 17: validate optional field ok when missing
######################################

cat > minimal.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

cat > schema_optional.conf <<'EOF'
[server]
host: string, required
port: int, required
debug: bool, optional
EOF

OUTPUT=$(../miniconf validate minimal.conf --schema schema_optional.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "validate optional field ok when missing"
else
  fail "validate optional field ok when missing (got: $OUTPUT)"
fi

######################################
# Test 18: validate multiple errors
######################################

cat > multi_err.conf <<'EOF'
[server]
debug = "yes"
EOF

cat > schema_multi.conf <<'EOF'
[server]
host: string, required
port: int, required
debug: bool, required
EOF

OUTPUT=$(../miniconf validate multi_err.conf --schema schema_multi.conf 2>&1)
ERR_COUNT=$(echo "$OUTPUT" | grep -c "ERROR:" || true)
if [ "$ERR_COUNT" -ge 3 ]; then
  pass "validate reports multiple errors"
else
  fail "validate reports multiple errors (got $ERR_COUNT errors: $OUTPUT)"
fi

######################################
# Test 19: validate ignores extra keys
######################################

cat > extra_keys.conf <<'EOF'
[server]
host = "localhost"
port = 8080
extra = "ignored"

[unknown]
foo = "bar"
EOF

cat > schema_small.conf <<'EOF'
[server]
host: string, required
port: int, required
EOF

OUTPUT=$(../miniconf validate extra_keys.conf --schema schema_small.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "validate ignores extra keys and sections"
else
  fail "validate ignores extra keys and sections (got: $OUTPUT)"
fi

######################################
# Test 20: validate missing section
######################################

cat > no_db.conf <<'EOF'
[server]
host = "localhost"
EOF

cat > schema_two.conf <<'EOF'
[server]
host: string, required

[database]
url: string, required
EOF

OUTPUT=$(../miniconf validate no_db.conf --schema schema_two.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[database\] url: required field missing'; then
  pass "validate missing section reports required fields"
else
  fail "validate missing section reports required fields (got: $OUTPUT)"
fi

######################################
# Test 21: check handles comments and blanks
######################################

cat > comments.conf <<'EOF'
# Comment

# Another
[app]

name = "test"
# more
version = 1
EOF

OUTPUT=$(../miniconf check comments.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "check handles comments and blank lines"
else
  fail "check handles comments and blank lines (got: $OUTPUT)"
fi

######################################
# Test 22: get with escape sequences
######################################

cat > escapes.conf <<'EOF'
[paths]
home = "C:\\Users\\test"
greeting = "say \"hello\""
EOF

OUTPUT=$(../miniconf get escapes.conf paths.home 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = '"C\Users\test"' ]; then
  pass "get with escape sequences"
else
  fail "get with escape sequences (got: $OUTPUT)"
fi

######################################
# Test 23: get empty list
######################################

cat > empty_list.conf <<'EOF'
[data]
items = []
EOF

OUTPUT=$(../miniconf get empty_list.conf data.items 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = '[]' ]; then
  pass "get empty list"
else
  fail "get empty list (got: $OUTPUT)"
fi

######################################
# Test 24: get negative int
######################################

cat > negint.conf <<'EOF'
[settings]
offset = -42
EOF

OUTPUT=$(../miniconf get negint.conf settings.offset 2>&1)
if [ $? -eq 0 ] && [ "$OUTPUT" = "-42" ]; then
  pass "get negative int"
else
  fail "get negative int (got: $OUTPUT)"
fi

##############################################################################
#                           V2 TESTS (25-40)
##############################################################################

######################################
# Test 25: validate range violation (too high)
######################################

cat > range_high.conf <<'EOF'
[network]
port = 99999
EOF

cat > schema_range.conf <<'EOF'
[network]
port: int, required, min=1, max=65535
EOF

OUTPUT=$(../miniconf validate range_high.conf --schema schema_range.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[network\] port: value 99999 out of range (1..65535)'; then
  pass "validate range violation (too high)"
else
  fail "validate range violation (too high) (got: $OUTPUT)"
fi

######################################
# Test 26: validate range violation (too low)
######################################

cat > range_low.conf <<'EOF'
[network]
port = 0
EOF

OUTPUT=$(../miniconf validate range_low.conf --schema schema_range.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[network\] port: value 0 out of range (1..65535)'; then
  pass "validate range violation (too low)"
else
  fail "validate range violation (too low) (got: $OUTPUT)"
fi

######################################
# Test 27: validate range OK (boundary)
######################################

cat > range_ok.conf <<'EOF'
[network]
port = 1
EOF

OUTPUT=$(../miniconf validate range_ok.conf --schema schema_range.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "OK"; then
  pass "validate range OK (boundary)"
else
  fail "validate range OK (boundary) (got: $OUTPUT)"
fi

######################################
# Test 28: validate list min_len violation
######################################

cat > short_list.conf <<'EOF'
[app]
tags = []
EOF

cat > schema_list.conf <<'EOF'
[app]
tags: list, required, min_len=1, max_len=5
EOF

OUTPUT=$(../miniconf validate short_list.conf --schema schema_list.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[app\] tags: list length 0 below minimum 1'; then
  pass "validate list min_len violation"
else
  fail "validate list min_len violation (got: $OUTPUT)"
fi

######################################
# Test 29: validate list max_len violation
######################################

cat > long_list.conf <<'EOF'
[app]
tags = ["a", "b", "c", "d", "e", "f"]
EOF

OUTPUT=$(../miniconf validate long_list.conf --schema schema_list.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q 'ERROR: \[app\] tags: list length 6 above maximum 5'; then
  pass "validate list max_len violation"
else
  fail "validate list max_len violation (got: $OUTPUT)"
fi

######################################
# Test 30: set existing key
######################################

cat > settest.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

OUTPUT=$(../miniconf set settest.conf server.port 9090 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "port = 9090"; then
  pass "set existing key"
else
  fail "set existing key (got: $OUTPUT)"
fi

######################################
# Test 31: set preserves other keys
######################################

# Verify host is still there after setting port
if echo "$OUTPUT" | grep -q 'host = "localhost"'; then
  pass "set preserves other keys"
else
  fail "set preserves other keys (got: $OUTPUT)"
fi

######################################
# Test 32: set new key in existing section
######################################

OUTPUT=$(../miniconf set settest.conf server.debug true 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "debug = true"; then
  pass "set new key in existing section"
else
  fail "set new key in existing section (got: $OUTPUT)"
fi

######################################
# Test 33: set creates new section
######################################

OUTPUT=$(../miniconf set settest.conf cache.ttl 300 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "\[cache\]" && echo "$OUTPUT" | grep -q "ttl = 300"; then
  pass "set creates new section"
else
  fail "set creates new section (got: $OUTPUT)"
fi

######################################
# Test 34: merge basic
######################################

cat > merge1.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

cat > merge2.conf <<'EOF'
[server]
port = 9090

[cache]
ttl = 300
EOF

OUTPUT=$(../miniconf merge merge1.conf merge2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q 'host = "localhost"' && echo "$OUTPUT" | grep -q "port = 9090" && echo "$OUTPUT" | grep -q "ttl = 300"; then
  pass "merge basic"
else
  fail "merge basic (got: $OUTPUT)"
fi

######################################
# Test 35: merge override
######################################

# port should be 9090 from merge2, not 8080 from merge1
if echo "$OUTPUT" | grep "port" | grep -q "9090"; then
  pass "merge override"
else
  fail "merge override (got: $OUTPUT)"
fi

######################################
# Test 36: merge sorted output
######################################

cat > merge_a.conf <<'EOF'
[zebra]
z = 1

[apple]
a = 1
EOF

cat > merge_b.conf <<'EOF'
[middle]
m = 1
EOF

OUTPUT=$(../miniconf merge merge_a.conf merge_b.conf 2>&1)
# Sections should be sorted: apple, middle, zebra
FIRST_SECTION=$(echo "$OUTPUT" | grep '^\[' | head -1)
if [ "$FIRST_SECTION" = "[apple]" ]; then
  pass "merge sorted output"
else
  fail "merge sorted output (got first section: $FIRST_SECTION)"
fi

######################################
# Test 37: diff no differences
######################################

cat > same1.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

cat > same2.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

OUTPUT=$(../miniconf diff same1.conf same2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "No differences"; then
  pass "diff no differences"
else
  fail "diff no differences (got: $OUTPUT)"
fi

######################################
# Test 38: diff modified value
######################################

cat > diff1.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

cat > diff2.conf <<'EOF'
[server]
host = "localhost"
port = 9090
EOF

OUTPUT=$(../miniconf diff diff1.conf diff2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "Modified: \[server\] port: 8080 -> 9090"; then
  pass "diff modified value"
else
  fail "diff modified value (got: $OUTPUT)"
fi

######################################
# Test 39: diff added key
######################################

cat > diff_add1.conf <<'EOF'
[server]
host = "localhost"
EOF

cat > diff_add2.conf <<'EOF'
[server]
host = "localhost"
port = 8080
EOF

OUTPUT=$(../miniconf diff diff_add1.conf diff_add2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "Added: \[server\] port = 8080"; then
  pass "diff added key"
else
  fail "diff added key (got: $OUTPUT)"
fi

######################################
# Test 40: diff removed key
######################################

OUTPUT=$(../miniconf diff diff_add2.conf diff_add1.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "Removed: \[server\] port = 8080"; then
  pass "diff removed key"
else
  fail "diff removed key (got: $OUTPUT)"
fi

######################################
# Test 41: diff added section
######################################

cat > diff_sec1.conf <<'EOF'
[server]
host = "localhost"
EOF

cat > diff_sec2.conf <<'EOF'
[server]
host = "localhost"

[cache]
ttl = 300
EOF

OUTPUT=$(../miniconf diff diff_sec1.conf diff_sec2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q "Added: \[cache\] ttl = 300"; then
  pass "diff added section"
else
  fail "diff added section (got: $OUTPUT)"
fi

######################################
# Test 42: diff string values with quotes
######################################

cat > diff_str1.conf <<'EOF'
[app]
name = "old"
EOF

cat > diff_str2.conf <<'EOF'
[app]
name = "new"
EOF

OUTPUT=$(../miniconf diff diff_str1.conf diff_str2.conf 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q 'Modified: \[app\] name: "old" -> "new"'; then
  pass "diff string values with quotes"
else
  fail "diff string values with quotes (got: $OUTPUT)"
fi

######################################
# Test 43: set string value
######################################

cat > setstr.conf <<'EOF'
[app]
name = "old"
EOF

OUTPUT=$(../miniconf set setstr.conf app.name '"new"' 2>&1)
if [ $? -eq 0 ] && echo "$OUTPUT" | grep -q 'name = "new"'; then
  pass "set string value"
else
  fail "set string value (got: $OUTPUT)"
fi

######################################
# Test 44: validate combined range and type errors
######################################

cat > combined_err.conf <<'EOF'
[network]
port = "hello"
timeout = -5
EOF

cat > schema_combined.conf <<'EOF'
[network]
port: int, required, min=1, max=65535
timeout: int, required, min=0, max=3600
EOF

OUTPUT=$(../miniconf validate combined_err.conf --schema schema_combined.conf 2>&1)
# port should have type error, timeout should have range error
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "port" && echo "$OUTPUT" | grep -q "timeout"; then
  pass "validate combined range and type errors"
else
  fail "validate combined range and type errors (got: $OUTPUT)"
fi

######################################
# Test 45: check file not found
######################################

OUTPUT=$(../miniconf check nonexistent.conf 2>&1)
if [ $? -ne 0 ] && echo "$OUTPUT" | grep -q "ERROR: file not found: nonexistent.conf"; then
  pass "check file not found"
else
  fail "check file not found (got: $OUTPUT)"
fi

######################################
# Cleanup & Summary
######################################

cd ..
rm -rf testdir

echo ""
echo "========================"
echo "PASSED: $PASS_COUNT"
echo "FAILED: $FAIL_COUNT"
echo "TOTAL:  $((PASS_COUNT + FAIL_COUNT))"
echo "========================"

if [ "$FAIL_COUNT" -eq 0 ]; then
  echo "ALL TESTS PASSED"
  exit 0
else
  exit 1
fi
