// Stress-testing ("对拍") core: reproducible comparison loop and output comparators.
// Pure logic (no subprocess), so it runs on every backend and is fully unit-testable.
// The CLI wires external programs into this same comparison core via the runner.

///|
/// How two outputs are compared.
pub(all) enum CompareMode {
  /// Trimmed string equality.
  Exact
  /// Ordered integer-sequence equality (strict parsing).
  Ints
  /// Integer multiset equality (order-insensitive).
  UnorderedInts
}

///|
/// A discovered counterexample, with everything needed to replay it.
pub(all) struct Failure {
  round : Int32
  seed : UInt64
  input : String
  brute_out : String
  fast_out : String
  reason : String
}

///|
/// Compare two outputs under `mode`; return `Some(reason)` on mismatch.
pub fn compare(brute : String, fast : String, mode : CompareMode) -> String? {
  match mode {
    Exact =>
      if brute.trim() == fast.trim() {
        None
      } else {
        Some("exact mismatch")
      }
    Ints => compare_ints(brute, fast, true)
    UnorderedInts => compare_ints(brute, fast, false)
  }
}

///|
fn read_all_ints(text : String) -> Array[Int64] raise @checker.CheckError {
  let s = @checker.InStream::new(text)
  let arr : Array[Int64] = []
  while true {
    s.skip_space()
    if s.eof() {
      break
    }
    arr.push(s.read_int())
  }
  s.read_eof()
  arr
}

///|
fn compare_ints(brute : String, fast : String, ordered : Bool) -> String? {
  try {
    let b = read_all_ints(brute)
    let f = read_all_ints(fast)
    if b.length() != f.length() {
      return Some("int count mismatch: \{b.length()} vs \{f.length()}")
    }
    if !ordered {
      sort_i64(b)
      sort_i64(f)
    }
    for i in 0..<b.length() {
      if b[i] != f[i] {
        return Some("int mismatch at position \{i}")
      }
    }
    None
  } catch {
    @checker.CheckError(msg) => Some("parse error: " + msg)
  }
}

///|
fn sort_i64(a : Array[Int64]) -> Unit {
  for i in 1..<a.length() {
    let key = a[i]
    let mut j = i - 1
    while j >= 0 && a[j] > key {
      a[j + 1] = a[j]
      j = j - 1
    }
    a[j + 1] = key
  }
}

///|
/// Run `rounds` reproducible comparisons. `gen` maps a per-round seed to an input;
/// `brute` and `fast` map an input to an output. Returns the first counterexample,
/// or `None` if all rounds agree. Same `seed` => same search => same result.
pub fn stress_inprocess(
  rounds : Int32,
  seed : UInt64,
  gen : (UInt64) -> String,
  brute : (String) -> String,
  fast : (String) -> String,
  mode : CompareMode,
) -> Failure? {
  let rng = @gen.Rng::new(seed)
  for i in 0..<rounds {
    let s = rng.next_u64()
    let input = gen(s)
    let b = brute(input)
    let f = fast(input)
    match compare(b, f, mode) {
      Some(reason) =>
        return Some({
          round: i,
          seed: s,
          input,
          brute_out: b,
          fast_out: f,
          reason,
        })
      None => ()
    }
  }
  None
}
