// Additional testlib-style built-in checkers.

///|
/// Check the output is a permutation of 1..n (each integer appears once).
pub fn check_permutation(
  output : String,
  n : Int32,
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let got : Array[Int64] = []
  for _ in 0..<n {
    got.push(s.read_int())
  }
  s.read_eof()
  sort_i64(got)
  for i in 0..<n {
    if got[i] != (i + 1).to_int64() {
      raise @checker.check_error("not a permutation of 1..\{n}")
    }
  }
}

///|
/// Check the output is a single case-insensitive "yes" or "no" token.
pub fn check_yes_no(output : String) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let t = s.read_token()
  s.read_eof()
  let low : Array[Char] = []
  for c in t.to_array() {
    low.push(c.to_ascii_lowercase())
  }
  let ls = String::from_array(low)
  if ls != "yes" && ls != "no" {
    raise @checker.check_error("expected yes/no, got \{t}")
  }
}

///|
/// Check the output is exactly one token equal to `expected`.
pub fn check_token(
  output : String,
  expected : String,
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let t = s.read_token()
  s.read_eof()
  if t != expected {
    raise @checker.check_error("expected token \{expected}, got \{t}")
  }
}

///|
/// Check the output is a well-formed strict double sequence of any length.
pub fn check_double_sequence(output : String) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  while true {
    s.skip_space()
    if s.eof() {
      break
    }
    let _ = s.read_double()
  }
  s.read_eof()
}
