# fs (auto-imported, effect functions)
```
fs.read_text(path) -> Result[String, IoError]
fs.read_bytes(path) -> Result[List[Int], IoError]
fs.read_lines(path) -> Result[List[String], IoError]
fs.write(path, content) -> Result[Unit, IoError]
fs.write_bytes(path, bytes) -> Result[Unit, IoError]
fs.append(path, content) -> Result[Unit, IoError]
fs.mkdir_p(path) -> Result[Unit, IoError]
fs.exists?(path) -> Bool
fs.remove(path) -> Result[Unit, IoError]
fs.list_dir(path) -> Result[List[String], IoError]
```
