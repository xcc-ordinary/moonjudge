// Tests for unordered-double and token-sequence checkers.

///|
fn raised_m(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "unordered doubles accepts shuffled within eps" {
  @checkers.check_unordered_doubles("2.0 1.0 3.0", [1.0, 2.0, 3.0])
  @checkers.check_unordered_doubles("1.0000001 2.0", [2.0, 1.0])
}

///|
test "unordered doubles rejects wrong multiset" {
  assert_eq(
    raised_m(() => @checkers.check_unordered_doubles("1.0 1.0", [1.0, 2.0])),
    true,
  )
  assert_eq(
    raised_m(() => @checkers.check_unordered_doubles("1.0", [1.0, 2.0])),
    true,
  )
}

///|
test "tokens exact sequence" {
  @checkers.check_tokens("alpha beta gamma", ["alpha", "beta", "gamma"])
  assert_eq(
    raised_m(() => @checkers.check_tokens("alpha beta", ["beta", "alpha"])),
    true,
  )
  assert_eq(
    raised_m(() => @checkers.check_tokens("alpha", ["alpha", "beta"])),
    true,
  )
}

///|
test "tokens ignore case" {
  @checkers.check_tokens("YES No", ["yes", "no"], ignore_case=true)
  assert_eq(
    raised_m(() => @checkers.check_tokens("YES", ["no"], ignore_case=true)),
    true,
  )
}
