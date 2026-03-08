# Almide (.almd)

Do NOT install anything, clone repos, or run cargo.

## Patterns

```almide
module app
import fs                              (* only fs needs import; int,string,list,map,env are auto-imported *)

type AppError = | Custom(String) | Io(IoError) deriving From

(* --- Int is i64, wraps automatically. NEVER use % 2^64. --- *)
fn hash(data: List[Int]) -> String = {
  let h = list.fold(data, 1469598103934665603, fn(h, b) => (h ^ b) * 1099511628211)
  string.pad_left(int.to_hex(h), 16, "0")     (* int.to_hex handles sign correctly *)
}

(* --- string.lines for splitting text, list.get_or for safe access --- *)
effect fn print_lines(path: String) -> Result[Unit, AppError] = {
  let lines = string.lines(fs.read_text(path))
  for line in lines {
    println(line)
  }
  ok(())
}

fn parse_pair(line: String) -> List[String] = {
  let parts = string.split(line, " ")
  let key = list.get_or(parts, 0, "")
  let val = list.get_or(parts, 1, "")
  [key, val]
}

(* --- use Map for key-value lookups --- *)
effect fn parse_config(text: String) -> Result[Map[String, String], AppError] = {
  let lines = list.filter(string.split(text, "\n"), fn(l) => string.len(l) > 0)
  let config = list.fold(lines, map.new(), fn(m, line) => {
    let parts = string.split(line, " ")
    let key = match list.get(parts, 0) { some(v) => v, none => "" }
    let val = match list.get(parts, 1) { some(v) => v, none => "" }
    map.set(m, key, val)
  })
  ok(config)
}

effect fn main(args: List[String]) -> Result[Unit, AppError] = {
  match list.get(args, 1) {
    some("run") => { println("running") ok(()) },
    some(other) => err(Custom("unknown: " ++ other)),
    none => { println("usage: app <cmd>") ok(()) },
  }
}
```

## Syntax Summary

```
(* Types *)     Int String Bool Unit Float List[T] Map[K,V] Option[T] Result[T,E]
(* Fn *)        fn name(x: T) -> R = expr
(* Effect *)    effect fn name(x: T) -> Result[R, E] = expr
(* If *)        if cond then a else b                  (* else is MANDATORY *)
(* Match *)     match x { some(v) => v, none => "" }
(* For *)       for x in xs { println(x) }
                for (i, x) in list.enumerate(xs) { ... }   (* tuple destructuring *)
(* Do loop *)   do { guard cond else ok(()) ... }      (* only for dynamic break conditions *)
(* Guard *)     guard cond else err(msg)               (* early exit *)
(* Lambda *)    fn(x) => expr
(* Concat *)    "a" ++ "b"   [1] ++ [2]               (* ++ for string AND list *)
(* XOR *)       a ^ b
(* Interp *)    "hello ${name}"
(* Raw str *)   r"\d+"                                 (* no escape processing *)
(* Let/Var *)   let x = 1    var y = 2    y = 3
(* Tuple *)     (1, "a")
(* io *)        println(s)  (* no print, only println *)
```

## Stdlib — read the relevant stdlib-xxx.md files for full signatures

```
(* auto-imported *)  string list map int float fs path env process
(* import required *)  json math random time regex
```

Reference files (read only what you need):
- [stdlib-string.md](./stdlib-string.md) — trim split join len lines chars contains replace index_of starts_with? is_digit? ...
- [stdlib-list.md](./stdlib-list.md) — get get_or len sort map filter find fold enumerate zip flatten take drop unique ...
- [stdlib-map.md](./stdlib-map.md) — new get set contains remove keys values entries from_list ...
- [stdlib-fs.md](./stdlib-fs.md) — read_text write read_lines append mkdir_p exists? remove list_dir ...
- [stdlib-io.md](./stdlib-io.md) — path env process println ...
- [stdlib-int.md](./stdlib-int.md) — int.to_string to_hex float.to_string parse ...
- [stdlib-json.md](./stdlib-json.md) — parse stringify get get_string get_int get_array keys ...
- [stdlib-extra.md](./stdlib-extra.md) — math random time regex

## Full language reference — see [CHEATSHEET.md](./CHEATSHEET.md)
