# int / float (auto-imported)
```
int.to_string(n) -> String
int.to_hex(n) -> String
int.parse(s) -> Result[Int, String]
int.parse_hex(s) -> Result[Int, String]
int.abs(n) -> Int
int.min(a, b) -> Int
int.max(a, b) -> Int

(* bitwise operations *)
int.band(a, b) -> Int
int.bor(a, b) -> Int
int.bxor(a, b) -> Int
int.bshl(a, n) -> Int
int.bshr(a, n) -> Int
int.bnot(a) -> Int

(* wrapping arithmetic — for hash algorithms on fixed-width integers *)
int.wrap_add(a, b, bits) -> Int     (* e.g. int.wrap_add(x, y, 64) for u64 *)
int.wrap_mul(a, b, bits) -> Int
int.rotate_right(a, n, bits) -> Int
int.rotate_left(a, n, bits) -> Int
int.to_u32(a) -> Int                (* mask to 32-bit unsigned *)
int.to_u8(a) -> Int                 (* mask to 8-bit unsigned *)

float.to_string(n) -> String
float.to_int(n) -> Int
float.from_int(n) -> Float
float.round(n) -> Float
float.floor(n) -> Float
float.ceil(n) -> Float
float.abs(n) -> Float
float.sqrt(n) -> Float
float.parse(s) -> Result[Float, String]
```
