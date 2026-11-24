// Dogfooding #2: lower_bound binary search with the classic "<=" bug
// (returns upper_bound, wrong when the target has duplicates).

///|
fn lb_parse(input : String) -> (Int32, Int64, Array[Int64]) {
  let s = @checker.InStream::new(input)
  let n = s.read_int() catch { _ => 0L }
  let target = s.read_int() catch { _ => 0L }
  let a : Array[Int64] = []
  for _ in 0L..<n {
    a.push(s.read_int() catch { _ => 0L })
  }
  (n.to_int(), target, a)
}

///|
fn lb_gen(s : UInt64) -> String {
  let r = @gen.Rng::new(s)
  let n = r.next_int(1L, 8L)
  let a : Array[Int64] = []
  for _ in 0L..<n {
    a.push(r.next_int(0L, 5L))
  }
  for i in 1..<a.length() {
    let key = a[i]
    let mut j = i - 1
    while j >= 0 && a[j] > key {
      a[j + 1] = a[j]
      j = j - 1
    }
    a[j + 1] = key
  }
  let target = r.next_int(0L, 5L)
  let parts : Array[String] = ["\{n}", "\{target}"]
  for x in a {
    parts.push("\{x}")
  }
  parts.join(" ")
}

///|
fn lb_brute(input : String) -> String {
  let (n, target, a) = lb_parse(input)
  let mut ans = n
  for i in 0..<n {
    if a[i] >= target {
      ans = i
      break
    }
  }
  "\{ans}"
}

///|
fn lb_buggy(input : String) -> String {
  let (n, target, a) = lb_parse(input)
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    if a[mid] <= target {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  "\{lo}"
}

///|
fn lb_correct(input : String) -> String {
  let (n, target, a) = lb_parse(input)
  let mut lo = 0
  let mut hi = n
  while lo < hi {
    let mid = (lo + hi) / 2
    if a[mid] < target {
      lo = mid + 1
    } else {
      hi = mid
    }
  }
  "\{lo}"
}

///|
fn to_i32(s : String) -> Int32 {
  (@checker.InStream::new(s).read_int() catch { _ => 0L }).to_int()
}

///|
test "dogfood: stress catches lower_bound duplicate bug" {
  let fail = @stress.stress_inprocess(
    2000,
    7UL,
    lb_gen,
    lb_brute,
    lb_buggy,
    @stress.CompareMode::Ints,
  )
  match fail {
    Some(f) => {
      println(
        "lower_bound counterexample: input=[\{f.input}] brute=\{f.brute_out} buggy=\{f.fast_out}",
      )
      assert_eq(to_i32(f.brute_out) < to_i32(f.fast_out), true)
    }
    None => assert_eq(true, false)
  }
}

///|
test "dogfood: correct lower_bound passes stress" {
  let fail = @stress.stress_inprocess(
    2000,
    7UL,
    lb_gen,
    lb_brute,
    lb_correct,
    @stress.CompareMode::Ints,
  )
  assert_true(fail is None)
}
