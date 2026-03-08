# list (auto-imported)
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
