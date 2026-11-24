// Regression tests for the tolerance-based double checkers.

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
test "check_double within tolerance" {
  @checkers.check_double("3.14159", 3.14159)
  @checkers.check_double("1.0000001", 1.0, eps=1.0e-6)
}

///|
test "check_double rejects out of tolerance" {
  assert_eq(
    raised_d(() => @checkers.check_double("1.1", 1.0, eps=1.0e-6)),
    true,
  )
}

///|
test "check_double relative tolerance for large values" {
  @checkers.check_double("1000000.5", 1000000.0, eps=1.0e-6)
}

///|
test "check_doubles sequence" {
  @checkers.check_doubles("1.0 2.0 3.0", [1.0, 2.0, 3.0])
}

///|
test "check_doubles rejects wrong count" {
  assert_eq(
    raised_d(() => @checkers.check_doubles("1.0 2.0", [1.0, 2.0, 3.0])),
    true,
  )
}

///|
test "double_close basics" {
  assert_eq(@checkers.double_close(1.0, 1.0, 1.0e-9), true)
  assert_eq(@checkers.double_close(1.0, 2.0, 1.0e-9), false)
}
