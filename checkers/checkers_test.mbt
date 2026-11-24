///|
fn raised(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "check_ints accepts valid sequence" {
  @checkers.check_ints("1 2 3", 3)
}

///|
test "check_ints accepts bounds" {
  @checkers.check_ints("0 5 10", 3, min=0L, max=10L)
}

///|
test "check_ints rejects wrong count" {
  assert_eq(raised(() => @checkers.check_ints("1 2", 3)), true)
}

///|
test "check_ints rejects trailing content" {
  assert_eq(raised(() => @checkers.check_ints("1 2 3 4", 3)), true)
}

///|
test "check_ints rejects out of bounds" {
  assert_eq(raised(() => @checkers.check_ints("1 99", 2, max=10L)), true)
}

///|
test "unordered accepts permutation" {
  @checkers.check_unordered_ints("3 1 2", [1L, 2L, 3L])
}

///|
test "unordered accepts duplicates" {
  @checkers.check_unordered_ints("2 1 2", [1L, 2L, 2L])
}

///|
test "unordered rejects mismatch" {
  assert_eq(
    raised(() => @checkers.check_unordered_ints("1 2 4", [1L, 2L, 3L])),
    true,
  )
}

///|
test "unordered rejects wrong count" {
  assert_eq(
    raised(() => @checkers.check_unordered_ints("1 2", [1L, 2L, 3L])),
    true,
  )
}
