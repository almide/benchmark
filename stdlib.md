# Almide Standard Library Reference

## Auto-imported modules

These are available without `import`.

### string
```
string.trim(s) -> String
string.split(s, sep) -> List[String]
string.join(list, sep) -> String
string.len(s) -> Int
string.lines(s) -> List[String]
string.pad_left(s, n, ch) -> String
string.slice(s, start) -> String
string.slice(s, start, end) -> String
string.contains(s, sub) -> Bool
string.starts_with?(s, prefix) -> Bool
string.ends_with?(s, suffix) -> Bool
string.to_upper(s) -> String
string.to_lower(s) -> String
string.replace(s, from, to) -> String
string.to_int(s) -> Result[Int, String]
string.to_bytes(s) -> List[Int]
string.from_bytes(bytes) -> String
string.char_at(s, i) -> Option[String]
string.chars(s) -> List[String]
string.index_of(s, needle) -> Option[Int]
string.repeat(s, n) -> String
string.is_digit?(s) -> Bool
string.is_alpha?(s) -> Bool
string.is_alphanumeric?(s) -> Bool
string.is_whitespace?(s) -> Bool
```
All support UFCS: `s.trim()`, `s.chars()`, `s.is_digit?()`, etc.

### list
```
list.len(xs) -> Int
list.get(xs, i) -> Option[T]
list.get_or(xs, i, default) -> T
list.sort(xs) -> List[T]
list.sort_by(xs, fn(x) => key) -> List[T]
list.reverse(xs) -> List[T]
list.contains(xs, x) -> Bool
list.any(xs, fn(x) => Bool) -> Bool
list.all(xs, fn(x) => Bool) -> Bool
list.each(xs, fn(x) => Unit) -> Unit
list.map(xs, fn(x) => y) -> List[U]
list.filter(xs, fn(x) => Bool) -> List[T]
list.find(xs, fn(x) => Bool) -> Option[T]
list.fold(xs, init, fn(acc, x) => acc) -> U
list.enumerate(xs) -> List[(Int, T)]
list.zip(a, b) -> List[(T, U)]
list.flatten(xss) -> List[T]
list.take(xs, n) -> List[T]
list.drop(xs, n) -> List[T]
list.unique(xs) -> List[T]
```
All support UFCS: `xs.map(fn(x) => ...)`, `xs.len()`, etc.

### map
```
map.new() -> Map[K, V]
map.get(m, k) -> Option[V]
map.get_or(m, k, default) -> V
map.set(m, k, v) -> Map[K, V]          (* returns new map *)
map.contains(m, k) -> Bool
map.remove(m, k) -> Map[K, V]
map.keys(m) -> List[K]                  (* sorted *)
map.values(m) -> List[V]
map.len(m) -> Int
map.entries(m) -> List[(K, V)]
map.from_list(xs, fn(x) => (k, v)) -> Map[K, V]
```

### int / float
```
int.to_string(n) -> String
int.to_hex(n) -> String
float.to_string(n) -> String
float.to_int(n) -> Int
float.round(n) -> Float
float.floor(n) -> Float
float.ceil(n) -> Float
float.abs(n) -> Float
float.sqrt(n) -> Float
float.parse(s) -> Result[Float, String]
```

### fs (filesystem) — effect functions
```
fs.read_text(path) -> Result[String, IoError]
fs.read_bytes(path) -> Result[List[Int], IoError]
fs.read_lines(path) -> Result[List[String], IoError]
fs.write(path, content) -> Result[Unit, IoError]
fs.write_bytes(path, bytes) -> Result[Unit, IoError]
fs.append(path, content) -> Result[Unit, IoError]
fs.mkdir_p(path) -> Result[Unit, IoError]
fs.exists?(path) -> Bool
fs.remove(path) -> Result[Unit, IoError]
fs.list_dir(path) -> Result[List[String], IoError]
```

### path
```
path.join(base, child) -> String
path.dirname(p) -> String
path.basename(p) -> String
path.extension(p) -> Option[String]
path.is_absolute?(p) -> Bool
```

### env — effect functions
```
env.unix_timestamp() -> Int
env.args() -> List[String]
env.get(name) -> Option[String]
env.set(name, value) -> Unit
env.cwd() -> Result[String, String]
```

### process — effect functions
```
process.exec(cmd, args) -> Result[String, String]
process.exit(code) -> Unit
process.stdin_lines() -> Result[List[String], String]
```

## Import-required modules

These need `import <module>` at the top of the file.

### json
```
import json

json.parse(text) -> Result[Json, String]
json.stringify(j) -> String
json.get(j, key) -> Option[Json]
json.get_string(j, key) -> Option[String]
json.get_int(j, key) -> Option[Int]
json.get_bool(j, key) -> Option[Bool]
json.get_array(j, key) -> Option[List[Json]]
json.keys(j) -> List[String]
json.to_string(j) -> Option[String]
json.to_int(j) -> Option[Int]
json.from_string(s) -> Json
json.from_int(n) -> Json
json.from_bool(b) -> Json
json.null() -> Json
json.array(items) -> Json
json.from_map(m) -> Json
```

### math
```
import math

math.min(a, b) -> Int
math.max(a, b) -> Int
math.abs(n) -> Int
math.pow(base, exp) -> Int
math.pi() -> Float
math.e() -> Float
math.sin(x) -> Float
math.cos(x) -> Float
math.tan(x) -> Float
math.log(x) -> Float
math.exp(x) -> Float
math.sqrt(x) -> Float
```

### random — effect functions
```
import random

random.int(min, max) -> Int            (* inclusive *)
random.float() -> Float                (* 0.0..1.0 *)
random.choice(xs) -> Option[T]
random.shuffle(xs) -> List[T]
```

### time
```
import time

time.now() -> Int                      (* unix timestamp, seconds *)
time.millis() -> Int                   (* unix timestamp, milliseconds *)
time.sleep(ms) -> Unit                 (* effect *)
time.year(ts) -> Int
time.month(ts) -> Int                  (* 1-12 *)
time.day(ts) -> Int                    (* 1-31 *)
time.hour(ts) -> Int                   (* 0-23 *)
time.minute(ts) -> Int                 (* 0-59 *)
time.second(ts) -> Int                 (* 0-59 *)
time.weekday(ts) -> Int                (* 0=Mon, 6=Sun *)
time.to_iso(ts) -> String             (* "2024-01-15T10:30:45Z" *)
time.from_parts(y, m, d, h, min, s) -> Int
```

### regex
```
import regex

regex.match?(pat, s) -> Bool           (* partial match *)
regex.full_match?(pat, s) -> Bool      (* entire string must match *)
regex.find(pat, s) -> Option[String]   (* first match *)
regex.find_all(pat, s) -> List[String] (* all matches *)
regex.replace(pat, s, rep) -> String   (* replace all *)
regex.replace_first(pat, s, rep) -> String
regex.split(pat, s) -> List[String]
regex.captures(pat, s) -> Option[List[String]]  (* capture groups only *)
```

Pattern syntax: `.` `*` `+` `?` `[abc]` `[^abc]` `[a-z]` `\d` `\w` `\s` `\D` `\W` `\S` `^` `$` `|` `()` `\\`

Use raw strings to avoid double-escaping: `r"\d+"` instead of `"\\d+"`.

## Built-in functions (no module prefix)
```
println(s)              (* print line to stdout *)
eprintln(s)             (* print line to stderr *)
assert_eq(a, b)
assert_ne(a, b)
assert(cond)
unwrap_or(opt, default)
```
