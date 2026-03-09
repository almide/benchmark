# list (auto-imported)
```
list.len(xs) -> Int
list.get(xs, i) -> Option[T]
list.get_or(xs, i, default) -> T
list.first(xs) -> Option[T]
list.last(xs) -> Option[T]
list.sort(xs) -> List[T]
list.sort_by(xs, fn(x) => key) -> List[T]
list.reverse(xs) -> List[T]
list.contains(xs, x) -> Bool
list.index_of(xs, x) -> Option[Int]
list.any(xs, fn(x) => Bool) -> Bool
list.all(xs, fn(x) => Bool) -> Bool
list.each(xs, fn(x) => Unit) -> Unit
list.map(xs, fn(x) => y) -> List[U]
list.flat_map(xs, fn(x) => List[U]) -> List[U]
list.filter(xs, fn(x) => Bool) -> List[T]
list.find(xs, fn(x) => Bool) -> Option[T]
list.fold(xs, init, fn(acc, x) => acc) -> U
list.enumerate(xs) -> List[(Int, T)]
list.zip(a, b) -> List[(T, U)]
list.flatten(xss) -> List[T]
list.take(xs, n) -> List[T]
list.drop(xs, n) -> List[T]
list.chunk(xs, n) -> List[List[T]]
list.unique(xs) -> List[T]
list.join(xs, sep) -> String
list.sum(xs) -> Int
list.product(xs) -> Int
list.min(xs) -> Option[T]
list.max(xs) -> Option[T]
list.is_empty?(xs) -> Bool
```
All support UFCS: `xs.map(fn(x) => ...)`, `xs.len()`, etc.
