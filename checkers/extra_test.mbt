// Regression tests for the additional built-in checkers.

///|
fn raised_e(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "permutation accepts" {
  @checkers.check_permutation("3 1 2", 3)
}

///|
test "permutation rejects duplicate" {
  assert_eq(raised_e(() => @checkers.check_permutation("1 1 2", 3)), true)
}

///|
test "permutation rejects out of range" {
  assert_eq(raised_e(() => @checkers.check_permutation("1 2 4", 3)), true)
}

///|
test "yes_no accepts case-insensitive" {
  @checkers.check_yes_no("YES")
  @checkers.check_yes_no("No")
  @checkers.check_yes_no("yes")
}

///|
test "yes_no rejects other" {
  assert_eq(raised_e(() => @checkers.check_yes_no("maybe")), true)
}

///|
test "token exact" {
  @checkers.check_token("hello", "hello")
  assert_eq(raised_e(() => @checkers.check_token("hello", "world")), true)
}

///|
test "double_sequence accepts" {
  @checkers.check_double_sequence("1.0 -2.5 3e2")
}

///|
test "double_sequence rejects malformed" {
  assert_eq(raised_e(() => @checkers.check_double_sequence("1.0 x")), true)
}
