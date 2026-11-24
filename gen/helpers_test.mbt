// Tests for the array / permutation generators.

///|
test "next_array length and range" {
  let r = @gen.Rng::new(3UL)
  let a = r.next_array(50, -5L, 5L)
  assert_eq(a.length(), 50)
  for x in a {
    assert_eq(x >= -5L && x <= 5L, true)
  }
}

///|
test "permutation is a permutation of 1..n" {
  let r = @gen.Rng::new(9UL)
  let a = r.permutation(100)
  assert_eq(a.length(), 100)
  a.sort()
  for i in 0..<100 {
    assert_eq(a[i], (i + 1).to_int64())
  }
}

///|
test "permutation reproducible" {
  let a = @gen.Rng::new(5UL).permutation(20)
  let b = @gen.Rng::new(5UL).permutation(20)
  for i in 0..<20 {
    assert_eq(a[i], b[i])
  }
}