// Dogfooding: a real CSP-style problem — maximum subarray sum.
// Brute force O(n^2) vs a buggy Kadane that fails on all-negative arrays
// (the classic "initialize best to 0" mistake). moonjudge catches it.

///|
fn parse_arr(input : String) -> Array[Int64] {
  let s = @checker.InStream::new(input)
  let n = s.read_int() catch { _ => 0L }
  let a : Array[Int64] = []
  for _ in 0L..<n {
    a.push(s.read_int() catch { _ => 0L })
  }
  a
}

///|
fn gen_case(s : UInt64) -> String {
  let r = @gen.Rng::new(s)
  let n = r.next_int(1L, 6L)
  let all_neg = s % 2UL == 0UL
  let parts : Array[String] = ["\{n}"]
  for _ in 0L..<n {
    let v = if all_neg { r.next_int(-10L, -1L) } else { r.next_int(-10L, 10L) }
    parts.push("\{v}")
  }
  parts.join(" ")
}

///|
fn brute(input : String) -> String {
  let a = parse_arr(input)
  let mut best = a[0]
  for i in 0..<a.length() {
    let mut sum = 0L
    for j in i..<a.length() {
      sum = sum + a[j]
      if sum > best {
        best = sum
      }
    }
  }
  "\{best}"
}

///|
fn kadane_buggy(input : String) -> String {
  let a = parse_arr(input)
  let mut best = 0L
  let mut cur = 0L
  for x in a {
    cur = cur + x
    if cur < 0L {
      cur = 0L
    }
    if cur > best {
      best = cur
    }
  }
  "\{best}"
}

///|
fn kadane_correct(input : String) -> String {
  let a = parse_arr(input)
  let mut best = a[0]
  let mut cur = a[0]
  for i in 1..<a.length() {
    let x = a[i]
    cur = if x > cur + x { x } else { cur + x }
    if cur > best {
      best = cur
    }
  }
  "\{best}"
}

///|
fn to_i(s : String) -> Int64 {
  @checker.InStream::new(s).read_int() catch {
    _ => 0L
  }
}

///|
test "dogfood: stress catches Kadane all-negative bug" {
  let fail = @stress.stress_inprocess(
    2000,
    42UL,
    gen_case,
    brute,
    kadane_buggy,
    @stress.CompareMode::Ints,
  )
  match fail {
    Some(f) => {
      println(
        "dogfood counterexample: input=[\{f.input}] brute=\{f.brute_out} buggy=\{f.fast_out}",
      )
      assert_eq(to_i(f.fast_out), 0L)
      assert_eq(to_i(f.brute_out) < 0L, true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "dogfood: correct Kadane passes stress" {
  let fail = @stress.stress_inprocess(
    2000,
    42UL,
    gen_case,
    brute,
    kadane_correct,
    @stress.CompareMode::Ints,
  )
  assert_true(fail is None)
}
