# Almide (.almd)

Write a single `.almd` file then run `bash build.sh && bash test-v1.sh`.
Do NOT install anything, clone repos, or run cargo. Do NOT read other .md files.

## Example: A Simple CLI Tool

```almide
module mytool

type AppError = | Custom(String) | Io(IoError) deriving From

fn hash_bytes(data: List[Int], seed: Int) -> Int = {
  list.fold(data, seed, fn(h, b) => (h ^ b) * 1099511628211)
}

effect fn main(args: List[String]) -> Result[Unit, AppError] = {
  let cmd = match args.get(1) { some(c) => c, none => "" }
  match cmd {
    "greet" => {
      let name = match args.get(2) { some(n) => n, none => "world" }
      println("Hello, " ++ name)
      ok(())
    },
    "count" => {
      let path = match args.get(2) { some(p) => p, none => "." }
      let files = fs.list_dir(path)
      println("Files: " ++ int.to_string(files.len()))
      ok(())
    },
    _ => { println("Unknown command") ok(()) },
  }
}
```

## Syntax

```
(* Types *)     Int String Bool Unit Float List[T] Map[K,V] Option[T] Result[T,E]
(* Fn *)        fn name(x: T) -> R = expr
(* Effect *)    effect fn name(x: T) -> Result[R, E] = { ... }   (* side effects *)
(* If *)        if cond then a else b                (* else MANDATORY *)
(* Match *)     match x { some(v) => v, none => "" }
(* For *)       for x in xs { ... }    for _ in 0..n { ... }
(* Range *)     0..5 = [0,1,2,3,4]     1..=5 = [1,2,3,4,5]
(* Guard *)     guard cond else err(msg)             (* early exit *)
(* Do loop *)   do { guard cond else ok(()) ... }    (* loop with break *)
(* Lambda *)    fn(x) => expr
(* Concat *)    "a" ++ "b"   [1] ++ [2]
(* Let/Var *)   let x = 1    var y = 2    y = 3
(* UFCS *)      x.len()  x.split(" ")  x.trim()     (* auto-resolves module by type *)
(* Interp *)    "hello ${name}"
(* Logic *)     and  or  not             (* NOT && || ! *)
(* XOR *)       a ^ b
(* Tuple *)     for (k, v) in map.entries(m) { ... }
(* Comment *)   (* block comment *)
```

## Common Patterns

```almide
(* Error type — always define this for CLI tools *)
type AppError = | Custom(String) | Io(IoError) deriving From

(* Int is i64 and wraps at 2^64 automatically. NEVER use % or mod for wrapping. *)
(* Just use arithmetic directly: h = (h ^ b) * prime *)

(* Read file, split into non-empty lines *)
let text = fs.read_text(path)
let lines = text.split("\n").filter(fn(l) => l.len() > 0)

(* Build a Map from lines like "key value" *)
let m = list.fold(lines, map.new(), fn(m, line) => {
  let parts = line.split(" ")
  let k = match parts.get(0) { some(v) => v, none => "" }
  let val = match parts.get(1) { some(v) => v, none => "" }
  map.set(m, k, val)
})

(* Walk a linked structure *)
var current = start
for _ in 0..1000 {
  if current.len() > 0 and current != "NONE" then {
    let data = fs.read_text(dir ++ current)
    (* process data, update current *)
    current = next
  } else {
    current = ""
  }
}

(* Extract a field from "prefix: value" line *)
let value = line.replace("prefix: ", "")

(* Parse a section after a marker line *)
var past_marker = false
var result: Map[String, String] = map.new()
for line in lines {
  if past_marker then {
    let parts = line.split(" ")
    result = map.set(result, parts.get_or(0, ""), parts.get_or(1, ""))
  } else {
    if line == "marker:" then { past_marker = true } else { past_marker = past_marker }
  }
}

(* Sorted output *)
let sorted = list.sort(items)
let joined = sorted.map(fn(x) => x ++ " " ++ val).join("\n")

(* Error exit pattern *)
if not fs.exists?(path) then {
  println("Error message")
  process.exit(1)
  ok(())
} else {
  (* normal logic *)
  ok(())
}
```

## Stdlib (all signatures — no other functions exist)

### string (auto-imported, UFCS works)
```
trim(s) split(s,sep) join(list,sep) len(s) lines(s) chars(s) to_bytes(s) from_bytes(bs)
contains(s,sub) starts_with?(s,pre) ends_with?(s,suf) index_of(s,needle)->Option[Int]
replace(s,from,to) slice(s,start) slice(s,start,end) to_upper(s) to_lower(s)
to_int(s)->Result[Int,String] pad_left(s,n,ch) pad_right(s,n,ch)
char_at(s,i)->Option[String] repeat(s,n) count(s,sub) reverse(s)
is_empty?(s) is_digit?(s) strip_prefix(s,pre)->Option[String] strip_suffix(s,suf)->Option[String]
```

### list (auto-imported, UFCS works)
```
len(xs) get(xs,i)->Option[T] get_or(xs,i,default) first(xs) last(xs)
sort(xs) sort_by(xs,fn(x)=>key) reverse(xs) contains(xs,x) index_of(xs,x)->Option[Int]
any(xs,f) all(xs,f) each(xs,f) map(xs,f) flat_map(xs,f) filter(xs,f)
find(xs,f)->Option[T] fold(xs,init,f) enumerate(xs)->List[(Int,T)]
zip(a,b) flatten(xss) take(xs,n) drop(xs,n) chunk(xs,n) unique(xs)
join(xs,sep)->String sum(xs) product(xs) min(xs)->Option[T] max(xs)->Option[T] is_empty?(xs)
```

### map (auto-imported)
```
new()->Map[K,V] get(m,k)->Option[V] get_or(m,k,default) set(m,k,v)->Map[K,V]
contains(m,k) remove(m,k) merge(a,b) keys(m)->List[K] values(m) len(m)
entries(m)->List[(K,V)] from_list(xs,f)->Map[K,V] is_empty?(m)
```

### int (auto-imported)
```
to_string(n) to_hex(n) parse(s)->Result[Int,String] parse_hex(s) abs(n) min(a,b) max(a,b)
band(a,b) bor(a,b) bxor(a,b) bshl(a,n) bshr(a,n) bnot(a)
```

### float (auto-imported)
```
to_string(n) to_int(n) from_int(n) parse(s) round(n) floor(n) ceil(n) abs(n) sqrt(n)
```

### fs (auto-imported, effect)
```
read_text(path)->Result[String,IoError] read_lines(path) write(path,content) append(path,content)
mkdir_p(path) exists?(path)->Bool is_dir?(path) is_file?(path)
remove(path) list_dir(path)->Result[List[String],IoError] copy(src,dst) rename(src,dst)
```

### env (auto-imported, effect)
```
unix_timestamp()->Int args()->List[String] get(name)->Option[String] cwd()
```

### path (auto-imported)
```
join(base,child) dirname(p) basename(p) extension(p)->Option[String]
```

### process (auto-imported, effect)
```
exec(cmd,args)->Result[String,String] exit(code) stdin_lines()
```

### json (import required)
```
parse(text)->Result[Json,String] stringify(j) get(j,key)->Option[Json]
get_string(j,key)->Option[String] get_int(j,key)->Option[Int] get_array(j,key)->Option[List[Json]]
keys(j) to_string(j)->Option[String] to_int(j)->Option[Int]
from_string(s)->Json from_int(n)->Json from_bool(b)->Json null() array(items) from_map(m)
```

### Other modules (import required)
```
(* import regex *)  regex.match?(pat,s) full_match?(pat,s) find(pat,s) find_all(pat,s) replace(pat,s,rep) split(pat,s) captures(pat,s)
(* import encoding *) encoding.hex_encode(bytes) hex_decode(s) base64_encode(bytes) base64_decode(s)
(* import math *)   math.pow(base,exp) pi() sin(x) cos(x) sqrt(x)
(* import random *) random.int(min,max) float() choice(xs) shuffle(xs)
```

## CRITICAL: Do NOT

- `% 18446744073709551616` or any modulo for wrapping → Int is i64 and wraps automatically
- `list[1,2]` → write `[1,2]`
- `if cond { }` → write `if cond then ... else ...`
- `|x| expr` → write `fn(x) => expr`
- `&&`/`||`/`!` → write `and`/`or`/`not`
- `fn foo[T]` → no user generics, use concrete types
- `string.length` → write `string.len`
- `println(42)` → write `println(int.to_string(42))`
- `let _ = x` → `_` only in match patterns and for-loop bindings
