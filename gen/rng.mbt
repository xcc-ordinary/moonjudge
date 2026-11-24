// Seedable, reproducible pseudo-random generation for stress testing.
// Same seed => same data sequence, so any failing case can be replayed.

///|
/// xorshift64* generator: fast, deterministic, good enough for test data.
pub struct Rng {
  mut state : UInt64
}

///|
/// Create a generator. A zero seed is remapped to a fixed non-zero constant.
pub fn Rng::new(seed : UInt64) -> Rng {
  { state: if seed == 0UL { 0x9E3779B97F4A7C15UL } else { seed }, }
}

///|
/// Advance the state and return the next 64-bit unsigned value.
pub fn Rng::next_u64(self : Rng) -> UInt64 {
  let mut x = self.state
  x = x ^ (x >> 12)
  x = x ^ (x << 25)
  x = x ^ (x >> 27)
  self.state = x
  x * 0x2545F4914F6CDD1DUL
}

///|
/// Return an integer in the inclusive range `[min, max]`.
/// Uses modulo mapping; the bias is negligible for typical test ranges.
pub fn Rng::next_int(self : Rng, min : Int64, max : Int64) -> Int64 {
  let span = (max - min + 1L).reinterpret_as_uint64()
  min + (self.next_u64() % span).reinterpret_as_int64()
}

///|
/// Generate an array of `n` integers, each in the inclusive range `[min, max]`.
pub fn Rng::next_array(
  self : Rng,
  n : Int32,
  min : Int64,
  max : Int64,
) -> Array[Int64] {
  let a : Array[Int64] = []
  for _ in 0..<n {
    a.push(self.next_int(min, max))
  }
  a
}

///|
/// Generate a uniformly random permutation of `1..n` (Fisher-Yates shuffle).
pub fn Rng::permutation(self : Rng, n : Int32) -> Array[Int64] {
  let a : Array[Int64] = []
  for i in 0..<n {
    a.push((i + 1).to_int64())
  }
  for i in 0..<n {
    let j = self.next_int(i.to_int64(), (n - 1).to_int64()).to_int()
    let tmp = a[i]
    a[i] = a[j]
    a[j] = tmp
  }
  a
}
