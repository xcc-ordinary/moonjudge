///|
test "rng is reproducible for the same seed" {
  let a = @gen.Rng::new(42UL)
  let b = @gen.Rng::new(42UL)
  for _ in 0..<100 {
    assert_eq(a.next_u64(), b.next_u64())
  }
}

///|
test "rng differs across seeds" {
  let a = @gen.Rng::new(1UL)
  let b = @gen.Rng::new(2UL)
  assert_eq(a.next_u64() == b.next_u64(), false)
}

///|
test "rng next_int stays in range" {
  let r = @gen.Rng::new(7UL)
  for _ in 0..<1000 {
    let v = r.next_int(-5L, 5L)
    assert_eq(v >= -5L && v <= 5L, true)
  }
}

///|
test "rng zero seed is remapped" {
  let r = @gen.Rng::new(0UL)
  assert_eq(r.next_u64() == 0UL, false)
}
