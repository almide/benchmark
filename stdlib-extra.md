# math, random, time, regex (import required)

## math
```
import math

math.min(a, b) -> Int       math.max(a, b) -> Int
math.abs(n) -> Int          math.pow(base, exp) -> Int
math.pi() -> Float          math.e() -> Float
math.sin(x) -> Float        math.cos(x) -> Float
math.tan(x) -> Float        math.log(x) -> Float
math.exp(x) -> Float        math.sqrt(x) -> Float
```

## random (effect)
```
import random

random.int(min, max) -> Int            (* inclusive *)
random.float() -> Float                (* 0.0..1.0 *)
random.choice(xs) -> Option[T]
random.shuffle(xs) -> List[T]
```

## time
```
import time

time.now() -> Int                      (* unix timestamp, seconds *)
time.millis() -> Int                   (* unix timestamp, milliseconds *)
time.sleep(ms) -> Unit                 (* effect *)
time.year(ts) -> Int                   time.month(ts) -> Int    (* 1-12 *)
time.day(ts) -> Int                    time.hour(ts) -> Int     (* 0-23 *)
time.minute(ts) -> Int                 time.second(ts) -> Int   (* 0-59 *)
time.weekday(ts) -> Int                (* 0=Mon, 6=Sun *)
time.to_iso(ts) -> String             (* "2024-01-15T10:30:45Z" *)
time.from_parts(y, m, d, h, min, s) -> Int
```

## regex
```
import regex

regex.match?(pat, s) -> Bool           (* partial match *)
regex.full_match?(pat, s) -> Bool      (* entire string must match *)
regex.find(pat, s) -> Option[String]   (* first match *)
regex.find_all(pat, s) -> List[String] (* all matches *)
regex.replace(pat, s, rep) -> String   (* replace all *)
regex.replace_first(pat, s, rep) -> String
regex.split(pat, s) -> List[String]
regex.captures(pat, s) -> Option[List[String]]
```
Pattern syntax: `.` `*` `+` `?` `[abc]` `[^abc]` `[a-z]` `\d` `\w` `\s` `^` `$` `|` `()`
Use raw strings: `r"\d+"` instead of `"\\d+"`
