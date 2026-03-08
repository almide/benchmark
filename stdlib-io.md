# path, env, process (auto-imported)

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
env.args() -> List[String]
env.get(name) -> Option[String]
env.set(name, value) -> Unit
env.cwd() -> Result[String, String]
```

## process (effect)
```
process.exec(cmd, args) -> Result[String, String]
process.exit(code) -> Unit
process.stdin_lines() -> Result[List[String], String]
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
