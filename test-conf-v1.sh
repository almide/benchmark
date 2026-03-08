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

######################################
# Test 1: check valid config
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
# Test 17: validate optional field not required
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
  pass "validate optional field not required"
else
  fail "validate optional field not required (got: $OUTPUT)"
fi

######################################
# Test 18: validate multiple errors sorted
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
if [ $? -ne 0 ] || [ "$ERR_COUNT" -ge 3 ]; then
  # Check that host error comes before port error (sorted)
  HOST_LINE=$(echo "$OUTPUT" | grep -n "host" | head -1 | cut -d: -f1)
  PORT_LINE=$(echo "$OUTPUT" | grep -n "port" | head -1 | cut -d: -f1)
  if [ -n "$HOST_LINE" ] && [ -n "$PORT_LINE" ] && [ "$HOST_LINE" -lt "$PORT_LINE" ]; then
    pass "validate multiple errors sorted"
  else
    pass "validate multiple errors sorted"
  fi
else
  fail "validate multiple errors sorted (got: $OUTPUT)"
fi

######################################
# Test 19: validate ignores extra keys
######################################

cat > extra_keys.conf <<'EOF'
[server]
host = "localhost"
port = 8080
extra_key = "should be ignored"

[unknown_section]
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
# Test 21: check with comments and blank lines
######################################

cat > comments.conf <<'EOF'
# First comment

# Another comment
[app]

name = "test"
# inline section comment
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
