// Regression tests for strict double reading.

///|
fn raised_d(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "read_double basic" {
  let s = @checker.InStream::new("3.14")
  assert_eq(s.read_double(), 3.14)
}

///|
test "read_double signed exponent" {
  let s = @checker.InStream::new("-1.5e2 2")
  assert_eq(s.read_double(), -150.0)
  assert_eq(s.read_double(), 2.0)
}

///|
test "read_double rejects leading zero" {
  let s = @checker.InStream::new("00.5")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double rejects bare fraction" {
  let s = @checker.InStream::new(".5")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double rejects negative zero" {
  let s = @checker.InStream::new("-0.0")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double rejects trailing garbage" {
  let s = @checker.InStream::new("1.0x")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double rejects overflow to infinity" {
  let s = @checker.InStream::new("1e999")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double rejects negative infinity" {
  let s = @checker.InStream::new("-1e999")
  assert_eq(
    raised_d(() => {
      let _ = s.read_double()
      ()
    }),
    true,
  )
}

///|
test "read_double accepts large finite" {
  let s = @checker.InStream::new("1e308")
  assert_eq(s.read_double().is_finite(), true)
}
