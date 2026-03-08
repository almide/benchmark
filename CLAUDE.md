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

(* --- iterate with for...in, NOT do+guard+var --- *)
effect fn print_lines(path: String) -> Result[Unit, AppError] = {
  let text = fs.read_text(path)
  let lines = list.filter(string.split(text, "\n"), fn(l) => string.len(l) > 0)
  for line in lines {
    println(line)
  }
  ok(())
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

## Quick Reference

```
(* Types *)     Int String Bool Unit List[T] Map[K,V] Option[T] Result[T,E]
(* Fn *)        fn name(x: T) -> R = expr
(* Effect *)    effect fn name(x: T) -> Result[R, E] = expr
(* If *)        if cond then a else b                  (* else is MANDATORY *)
(* Match *)     match x { some(v) => v, none => "" }
(* For *)       for x in xs { println(x) }
(* Do loop *)   do { guard cond else ok(()) ... }      (* only for dynamic break conditions *)
(* Guard *)     guard cond else err(msg)               (* early exit *)
(* Lambda *)    fn(x) => expr
(* Concat *)    "a" ++ "b"   [1] ++ [2]               (* ++ for string AND list *)
(* XOR *)       a ^ b
(* Interp *)    "hello ${name}"
(* Let/Var *)   let x = 1    var y = 2    y = 3

(* fs *)        read_text(p) write(p,s) append(p,s) mkdir_p(p) exists?(p)->Bool
(* string *)    trim split join len pad_left slice to_bytes contains starts_with? ends_with? replace to_int char_at
(* list *)      get(i)->Option len sort contains each map filter find fold
(* map *)       new() get(k)->Option set(k,v) contains(k) remove(k) keys()->List values() len entries from_list(xs,fn)
(* int *)       to_string to_hex
(* env *)       unix_timestamp() args()
(* io *)        println(s)  (* no print, only println *)
```
