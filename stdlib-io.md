# path, env, process, io (auto-imported)

## path
```
path.join(base, child) -> String
path.dirname(p) -> String
path.basename(p) -> String
path.extension(p) -> Option[String]
path.is_absolute?(p) -> Bool
```

## env (effect)
```
env.unix_timestamp() -> Int
env.millis() -> Int
env.args() -> List[String]
env.get(name) -> Option[String]
env.set(name, value) -> Unit
env.cwd() -> Result[String, String]
env.sleep_ms(ms) -> Unit
```

## process (effect)
```
process.exec(cmd, args) -> Result[String, String]
process.exec_status(cmd, args) -> Result[{code: Int, stdout: String, stderr: String}, String]
process.exit(code) -> Unit
process.stdin_lines() -> Result[List[String], String]
```

## io (effect)
```
io.read_line() -> String          (* read one line from stdin, blocking *)
io.print(s) -> Unit               (* print without newline *)
io.read_all() -> String           (* read all of stdin *)
```

## Built-in functions (no module prefix)
```
println(s)              (* print line to stdout *)
eprintln(s)             (* print line to stderr *)
assert_eq(a, b)
assert_ne(a, b)
assert(cond)
unwrap_or(opt, default)
```
