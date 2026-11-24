// Tests for the tolerance-based double comparison mode.

///|
test "compare doubles within tolerance" {
  assert_true(
    @stress.compare(
      "1.0 2.0",
      "1.0000001 2.0",
      @stress.CompareMode::Doubles(1.0e-6),
    )
    is None,
  )
}

///|
test "compare doubles rejects mismatch" {
  assert_true(
    @stress.compare("1.0", "2.0", @stress.CompareMode::Doubles(1.0e-6))
    is Some(_),
  )
}

///|
test "compare doubles rejects count" {
  assert_true(
    @stress.compare("1.0 2.0", "1.0", @stress.CompareMode::Doubles(1.0e-6))
    is Some(_),
  )
}

///|
test "compare doubles relative tolerance" {
  assert_true(
    @stress.compare(
      "1000000.0",
      "1000000.5",
      @stress.CompareMode::Doubles(1.0e-6),
    )
    is None,
  )
}
