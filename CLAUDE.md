# Almide (.almd) — Write minigit.almd, run `bash build.sh && bash test-v1.sh`

Do NOT install anything, clone repos, or run cargo.

## Grammar (EBNF)

```
program     = "module" IDENT import* decl*
import      = "import" IDENT
decl        = type_decl | fn_decl
type_decl   = "type" IDENT "=" "|" variant ("|" variant)* "deriving" "From"
variant     = IDENT "(" type ("," type)* ")"
fn_decl     = ["effect"] "fn" IDENT "(" params ")" "->" type "=" expr
type        = "Int" | "String" | "Bool" | "Unit" | IDENT | IDENT "[" type ("," type)* "]"
expr        = block | if_expr | match_expr | do_expr | guard | let | var | assign | binary | call | literal
block       = "{" stmt* expr "}"
if_expr     = "if" expr "then" expr "else" expr       (* else is MANDATORY *)
match_expr  = "match" expr "{" arm ("," arm)* "}"
arm         = pattern "=>" expr
pattern     = "some" "(" pattern ")" | "none" | "ok" "(" pattern ")" | "err" "(" pattern ")" | IDENT | LITERAL | "_"
do_expr     = "do" "{" (guard | stmt)* "}"            (* loop: use guard to break *)
guard       = "guard" expr "else" expr                 (* early exit / loop break *)
let         = "let" IDENT "=" expr
var         = "var" IDENT "=" expr
assign      = IDENT "=" expr
binary      = expr OP expr    (* OP: + - * / % ^ == != < > <= >= ++ and or *)
                               (* ++ for string/list concat, ^ for XOR, not for boolean neg *)
call        = IDENT "(" args ")" | IDENT "." IDENT "(" args ")"
lambda      = "fn" "(" params ")" "=>" expr
literal     = INT | STRING | "true" | "false" | "ok" "(" expr ")" | "err" "(" expr ")"
                               (* string interpolation: "hello ${name}" *)
```

## Stdlib

```
fs.read_text(path)->String  fs.write(path,s)  fs.mkdir_p(path)  fs.exists?(path)->Bool  fs.append(path,s)
string.trim(s) split(s,d)->List join(xs,d) len(s)->Int pad_left(s,w,c) slice(s,start) to_bytes(s)->List[Int]
string.contains(s,sub)->Bool starts_with?(s,p)->Bool ends_with?(s,p)->Bool replace(s,from,to)
list.get(xs,i)->Option  len(xs)->Int  sort(xs)  contains(xs,v)->Bool
list.map(xs,fn(x)=>e)  filter(xs,fn(x)=>b)  fold(xs,init,fn(a,x)=>e)
int.to_string(n)  int.to_hex(n)
env.unix_timestamp()->Int
println(s)  (* no print, only println *)
(* int, string, list, env are auto-imported — no import needed. Only fs requires: import fs *)
```

## Example

```
module app
import fs

type AppError = | Custom(String) | Io(IoError) deriving From

fn hash(s: String) -> String = string.pad_left(int.to_hex(list.fold(string.to_bytes(s), 0, fn(a,b) => (a ^ b) * 31)), 8, "0")

effect fn main(args: List[String]) -> Result[Unit, AppError] = {
  match list.get(args, 1) {
    some("save") => {
      let f = match list.get(args, 2) { some(v) => v, none => "out.txt" }
      guard fs.exists?(f) else err(Custom("not found"))
      let content = fs.read_text(f)
      fs.write("backup/" ++ hash(content), content)
      println("saved " ++ f)
      ok(())
    },
    none => { println("usage: app save <file>") ok(()) },
    _ => err(Custom("unknown command")),
  }
}
```
