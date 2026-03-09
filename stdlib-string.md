# string (auto-imported)
```
string.trim(s) -> String
string.trim_start(s) -> String
string.trim_end(s) -> String
string.split(s, sep) -> List[String]
string.join(list, sep) -> String
string.len(s) -> Int
string.lines(s) -> List[String]
string.pad_left(s, n, ch) -> String
string.pad_right(s, n, ch) -> String
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
string.count(s, sub) -> Int
string.reverse(s) -> String
string.is_empty?(s) -> Bool
string.is_digit?(s) -> Bool
string.is_alpha?(s) -> Bool
string.is_alphanumeric?(s) -> Bool
string.is_whitespace?(s) -> Bool
string.strip_prefix(s, prefix) -> Option[String]
string.strip_suffix(s, suffix) -> Option[String]
```
All support UFCS: `s.trim()`, `s.chars()`, `s.is_digit?()`, etc.
