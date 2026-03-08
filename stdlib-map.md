# map (auto-imported)
```
map.new() -> Map[K, V]
map.get(m, k) -> Option[V]
map.get_or(m, k, default) -> V
map.set(m, k, v) -> Map[K, V]          (* returns new map *)
map.contains(m, k) -> Bool
map.remove(m, k) -> Map[K, V]
map.keys(m) -> List[K]                  (* sorted *)
map.values(m) -> List[V]
map.len(m) -> Int
map.entries(m) -> List[(K, V)]
map.from_list(xs, fn(x) => (k, v)) -> Map[K, V]
```
