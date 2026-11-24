// Floating-point checkers with absolute/relative tolerance (testlib style).

///|
fn dabs(x : Double) -> Double {
  if x < 0.0 {
    -x
  } else {
    x
  }
}

///|
/// Tolerance test: |a-b| <= eps * max(1, |a|, |b|).
pub fn double_close(a : Double, b : Double, eps : Double) -> Bool {
  let diff = dabs(a - b)
  let mut scale = 1.0
  if dabs(a) > scale {
    scale = dabs(a)
  }
  if dabs(b) > scale {
    scale = dabs(b)
  }
  diff <= eps * scale
}

///|
/// Check the output is a single double close to `expected` within `eps`
/// (default 1.0e-6), followed by EOF.
pub fn check_double(
  output : String,
  expected : Double,
  eps? : Double,
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let got = s.read_double()
  s.read_eof()
  let tol = eps.unwrap_or(1.0e-6)
  if !double_close(got, expected, tol) {
    raise @checker.check_error("expected \{expected}, got \{got} (eps=\{tol})")
  }
}

///|
/// Check the output is exactly `expected.length()` doubles, each close to the
/// corresponding expected value within `eps` (default 1.0e-6), followed by EOF.
pub fn check_doubles(
  output : String,
  expected : ArrayView[Double],
  eps? : Double,
) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let tol = eps.unwrap_or(1.0e-6)
  for i in 0..<expected.length() {
    let got = s.read_double()
    if !double_close(got, expected[i], tol) {
      raise @checker.check_error(
        "mismatch at \{i}: expected \{expected[i]}, got \{got}",
      )
    }
  }
  s.read_eof()
}
