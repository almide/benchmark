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

(* fs *)        read_text(p) read_lines(p)->List write(p,s) append(p,s) mkdir_p(p) exists?(p)->Bool remove(p) list_dir(p)->List
(* string *)    trim split join len lines pad_left slice to_bytes from_bytes contains starts_with? ends_with? replace to_int char_at chars index_of(s,needle)->Option repeat(s,n) is_digit?(s)->Bool is_alpha?(s) is_alphanumeric?(s) is_whitespace?(s)
(* list *)      get(i)->Option get_or(i,default) len sort sort_by(fn) reverse contains any(fn) all(fn) each map filter find fold enumerate zip(a,b) flatten take(n) drop(n) unique
(* map *)       new() get(k)->Option get_or(k,default) set(k,v) contains(k) remove(k) keys()->List values() len entries from_list(xs,fn)
(* path *)      join(base,child) dirname(p) basename(p) extension(p)->Option is_absolute?(p)->Bool
(* json *)      parse(text)->Result[Json] stringify(j) get(j,k)->Option get_string get_int get_bool get_array keys from_string from_int from_bool null array from_map  (* requires: import json *)
(* int *)       to_string to_hex
(* env *)       unix_timestamp() args()
(* math *)      min(a,b) max(a,b) abs(n) pow(base,exp) pi() e() sin(x) cos(x) tan(x) log(x) exp(x) sqrt(x)  (* requires: import math *)
(* random *)    int(min,max) float() choice(xs)->Option shuffle(xs)  (* requires: import random *)
(* time *)      now()->Int millis()->Int sleep(ms) year(ts) month(ts) day(ts) hour(ts) minute(ts) second(ts) weekday(ts)->0=Mon to_iso(ts)->String from_parts(y,m,d,h,min,s)->Int  (* requires: import time *)
(* io *)        println(s)  (* no print, only println *)
```
