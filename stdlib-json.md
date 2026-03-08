# json (import required)
```
import json

json.parse(text) -> Result[Json, String]
json.stringify(j) -> String
json.get(j, key) -> Option[Json]
json.get_string(j, key) -> Option[String]
json.get_int(j, key) -> Option[Int]
json.get_bool(j, key) -> Option[Bool]
json.get_array(j, key) -> Option[List[Json]]
json.keys(j) -> List[String]
json.to_string(j) -> Option[String]
json.to_int(j) -> Option[Int]
json.from_string(s) -> Json
json.from_int(n) -> Json
json.from_bool(b) -> Json
json.null() -> Json
json.array(items) -> Json
json.from_map(m) -> Json
```
