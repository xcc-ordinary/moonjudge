// Built-in checkers composed from the strict checker core.

///|
/// Check that the output is exactly `n` integers (each within optional
/// inclusive bounds), followed by EOF.
pub fn check_ints(
  output : String,
  n : Int32,
  min? : Int64,
  max? : Int64,
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  for _ in 0..<n {
    let _ = s.read_int(min?, max?)
  }
  s.read_eof()
}

///|
/// Check that the output is a well-formed strict integer sequence of any length
/// (each token passes the strict integer rules), followed by EOF.
pub fn check_int_sequence(output : String) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  while true {
    s.skip_space()
    if s.eof() {
      break
    }
    let _ = s.read_int()
  }
  s.read_eof()
}

///|
/// Check that the output is a permutation (multiset) of `expected` integers,
/// in any order, followed by EOF.
pub fn check_unordered_ints(
  output : String,
  expected : ArrayView[Int64],
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let got : Array[Int64] = []
  while true {
    s.skip_space()
    if s.eof() {
      break
    }
    got.push(s.read_int())
  }
  s.read_eof()
  if got.length() != expected.length() {
    raise @checker.check_error(
      "wrong count: expected \{expected.length()}, got \{got.length()}",
    )
  }
  let exp : Array[Int64] = []
  for x in expected {
    exp.push(x)
  }
  sort_i64(got)
  sort_i64(exp)
  for i in 0..<got.length() {
    if got[i] != exp[i] {
      raise @checker.check_error("multiset mismatch at position \{i}")
    }
  }
}

///|
fn sort_i64(a : Array[Int64]) -> Unit {
  for i in 1..<a.length() {
    let key = a[i]
    let mut j = i - 1
    while j >= 0 && a[j] > key {
      a[j + 1] = a[j]
      j = j - 1
    }
    a[j + 1] = key
  }
}
