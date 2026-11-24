// Regression tests for the order-validation checker.

///|
fn raised_s(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "sorted accepts nondecreasing" {
  @checkers.check_sorted("1 1 2 3 3")
  @checkers.check_sorted("")
  @checkers.check_sorted("5")
}

///|
test "sorted rejects decreasing" {
  assert_eq(raised_s(() => @checkers.check_sorted("1 3 2")), true)
}

///|
test "sorted rejects malformed" {
  assert_eq(raised_s(() => @checkers.check_sorted("1 x")), true)
}