// Regression + demonstration tests for the stress core.
// The "planted bug" demo shows the tool actually catching a wrong solution.

///|
fn to_n(input : String) -> Int64 {
  @checker.InStream::new(input).read_int() catch {
    _ => 0L
  }
}

// Generator: a random n in [0, 100).

///|
fn gen_input(s : UInt64) -> String {
  let n = (s % 100UL).reinterpret_as_int64()
  "\{n}\n"
}

// Correct reference: sum 1..n.

///|
fn brute(input : String) -> String {
  let n = to_n(input)
  let mut sum = 0L
  for k in 1L..<=n {
    sum = sum + k
  }
  "\{sum}"
}

// Buggy "optimized" solution: wrong whenever n is a multiple of 7.

///|
fn fast_buggy(input : String) -> String {
  let n = to_n(input)
  let mut sum = 0L
  for k in 1L..<=n {
    sum = sum + k
  }
  if n % 7L == 0L {
    sum = sum - 1L
  }
  "\{sum}"
}

///|
test "stress finds the planted bug" {
  let fail = @stress.stress_inprocess(
    1000,
    42UL,
    gen_input,
    brute,
    fast_buggy,
    @stress.CompareMode::Exact,
  )
  match fail {
    Some(f) => {
      let n = to_n(f.input)
      assert_eq(n % 7L, 0L)
      assert_eq(f.brute_out == f.fast_out, false)
    }
    None => assert_eq(true, false)
  }
}

///|
test "stress passes a correct solution" {
  let fail = @stress.stress_inprocess(
    200,
    42UL,
    gen_input,
    brute,
    brute,
    @stress.CompareMode::Exact,
  )
  assert_true(fail is None)
}

///|
test "stress is reproducible by seed" {
  let f1 = @stress.stress_inprocess(
    1000,
    42UL,
    gen_input,
    brute,
    fast_buggy,
    @stress.CompareMode::Exact,
  )
  let f2 = @stress.stress_inprocess(
    1000,
    42UL,
    gen_input,
    brute,
    fast_buggy,
    @stress.CompareMode::Exact,
  )
  assert_eq(f1.unwrap().seed, f2.unwrap().seed)
  assert_eq(f1.unwrap().input, f2.unwrap().input)
}

///|
test "compare exact" {
  assert_true(
    @stress.compare("1 2 3", "1 2 3", @stress.CompareMode::Exact) is None,
  )
  assert_true(
    @stress.compare("1 2 3", "1 2 4", @stress.CompareMode::Exact) is Some(_),
  )
}

///|
test "compare ints ordered" {
  assert_true(
    @stress.compare("1 2 3", "1 2 3", @stress.CompareMode::Ints) is None,
  )
  assert_true(
    @stress.compare("1 2 3", "3 2 1", @stress.CompareMode::Ints) is Some(_),
  )
}

///|
test "compare ints unordered" {
  assert_true(
    @stress.compare("3 1 2", "1 2 3", @stress.CompareMode::UnorderedInts)
    is None,
  )
  assert_true(
    @stress.compare("1 2 2", "1 2 3", @stress.CompareMode::UnorderedInts)
    is Some(_),
  )
}

///|
test "compare ints rejects malformed" {
  assert_true(
    @stress.compare("1 2 x", "1 2 3", @stress.CompareMode::Ints) is Some(_),
  )
}
