// moonjudge CLI: local judging and stress testing.
// Subcommands: demo | judge | stress. Run via:
//   moon run cmd/moonjudge --target wasm -- demo

///|
fn main {
  let args = @env.args()
  if args.length() < 2 {
    print_usage()
    return
  }
  match args[1] {
    "demo" => demo()
    "judge" => judge_cli(args)
    "stress" => stress_cli(args)
    "batch" => batch_cli(args)
    _ => print_usage()
  }
}

///|
fn print_usage() -> Unit {
  println("moonjudge - local judge & stress testing for MoonBit")
  println("")
  println("usage:")
  println("  moonjudge demo")
  println(
    "      Run the built-in planted-bug stress demo; saves a counterexample.",
  )
  println("  moonjudge judge --prog \"CMD\" [--input FILE | --stdin TEXT]")
  println(
    "                  [--answer FILE] [--checker exact|ints|unordered|doubles]",
  )
  println("                  [--timeout MS]")
  println(
    "      Run a solution; with --answer, compare against a reference output.",
  )
  println("  moonjudge stress --gen \"CMD\" --brute \"CMD\" --fast \"CMD\"")
  println(
    "                   [--rounds N] [--seed S] [--checker MODE] [--timeout MS]",
  )
  println(
    "      Stress-test fast vs brute; the generator receives the round seed",
  )
  println(
    "      as its last argument. Saves the first counterexample for replay.",
  )
  println("  moonjudge batch --prog \"CMD\" --tests DIR")
  println(
    "                  [--checker MODE] [--timeout MS]",
  )
  println(
    "      Judge a program over every DIR/*.in case against its DIR/*.ans or *.out.",
  )
}

// ---- argument helpers ----

///|
fn get_opt(args : Array[String], name : String) -> String? {
  for i in 0..<args.length() {
    if args[i] == name && i + 1 < args.length() {
      return Some(args[i + 1])
    }
  }
  None
}

///|
fn parse_positive(s : String) -> Int32? {
  let v = @string.parse_int(s) catch {
    _ => return None
  }
  if v > 0 {
    Some(v)
  } else {
    None
  }
}

///|
fn parse_seed(s : String) -> UInt64 {
  @string.parse_uint64(s) catch {
    _ => 42UL
  }
}

///|
fn parse_mode(s : String) -> @stress.CompareMode {
  match s {
    "ints" => @stress.CompareMode::Ints
    "unordered" => @stress.CompareMode::UnorderedInts
    "doubles" => @stress.CompareMode::Doubles(1.0e-6)
    _ => @stress.CompareMode::Exact
  }
}

///|
fn split_cmd(s : String) -> (String, Array[String]) {
  let parts : Array[String] = []
  for tok in s.split(" ") {
    let t = tok.trim()
    if !t.is_empty() {
      parts.push(t.to_owned())
    }
  }
  if parts.length() == 0 {
    return ("", [])
  }
  let args : Array[String] = []
  for i in 1..<parts.length() {
    args.push(parts[i])
  }
  (parts[0], args)
}

///|
fn verdict_string(v : @checker.Verdict) -> String {
  match v {
    @checker.Verdict::AC => "AC"
    @checker.Verdict::WA(msg) => "WA: " + msg
    @checker.Verdict::TLE => "TLE"
    @checker.Verdict::RE(msg) => "RE: " + msg
    @checker.Verdict::CF(msg) => "CF: " + msg
  }
}

// ---- demo: a self-contained stress run that catches a planted bug ----

///|
fn to_n(input : String) -> Int64 {
  @checker.InStream::new(input).read_int() catch {
    _ => 0L
  }
}

///|
fn demo_gen(s : UInt64) -> String {
  let n = (s % 100UL).reinterpret_as_int64()
  "\{n}\n"
}

///|
fn demo_brute(input : String) -> String {
  let n = to_n(input)
  let mut sum = 0L
  for k in 1L..<=n {
    sum = sum + k
  }
  "\{sum}"
}

///|
fn demo_fast(input : String) -> String {
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
async fn demo() -> Unit {
  println("Stress demo: sum 1..n, buggy fast solution (wrong when n % 7 == 0).")
  let fail = @stress.stress_inprocess(
    1000,
    42UL,
    demo_gen,
    demo_brute,
    demo_fast,
    @stress.CompareMode::Exact,
  )
  match fail {
    Some(f) => {
      println("Counterexample at round \{f.round} (seed=\{f.seed}):")
      println("  input = \{f.input.trim()}")
      println("  brute = \{f.brute_out}")
      println("  fast  = \{f.fast_out}")
      println("  reason= \{f.reason}")
      save_failure(f)
    }
    None => println("No counterexample found.")
  }
}

///|
async fn save_failure(f : @stress.Failure) -> Unit {
  let dir = "moonjudge-failure/\{f.seed}"
  @fs.mkdir(dir, recursive=true, allow_existing=true)
  @fs.write_text(dir + "/input.txt", f.input)
  @fs.write_text(dir + "/brute.txt", f.brute_out)
  @fs.write_text(dir + "/fast.txt", f.fast_out)
  @fs.write_text(dir + "/seed.txt", "\{f.seed}")
  @fs.write_text(dir + "/reason.txt", f.reason)
  println("Saved counterexample to \{dir}/ (replay with the seed).")
}

// ---- judge: run one solution and judge its output ----

///|
async fn judge_cli(args : Array[String]) -> Unit {
  if get_opt(args, "--prog") is None {
    println("judge: need --prog \"CMD\"")
    return
  }
  let (p, a) = split_cmd(get_opt(args, "--prog").unwrap_or(""))
  let mode = parse_mode(get_opt(args, "--checker").unwrap_or("exact"))
  let timeout = match parse_positive(get_opt(args, "--timeout").unwrap_or("5000")) {
    Some(n) => n
    None => {
      println("judge: --timeout must be a positive integer")
      return
    }
  }
  let input = match get_opt(args, "--input") {
    Some(file) => @fs.read_text(file)
    None => get_opt(args, "--stdin").unwrap_or("")
  }
  let answer = match get_opt(args, "--answer") {
    Some(file) => Some(@fs.read_text(file))
    None => None
  }
  let r = @runner.run(p, a, stdin=input, timeout_ms=timeout)
  let check : (String) -> Unit raise @checker.CheckError = match answer {
    Some(exp) =>
      out => {
        match @stress.compare(exp, out, mode) {
          Some(reason) => raise @checker.check_error(reason)
          None => ()
        }
      }
    None =>
      match mode {
        @stress.CompareMode::Ints => out => @checkers.check_int_sequence(out)
        @stress.CompareMode::UnorderedInts =>
          out => @checkers.check_int_sequence(out)
        @stress.CompareMode::Doubles(_) =>
          out => @checkers.check_double_sequence(out)
        @stress.CompareMode::Exact =>
          out => {
            let _ = out
            ()
          }
      }
  }
  let v = @runner.judge(r, check)
  println(verdict_string(v))
}

// ---- stress: external generator / brute / fast ----

///|
async fn stress_cli(args : Array[String]) -> Unit {
  if get_opt(args, "--gen") is None ||
     get_opt(args, "--brute") is None ||
     get_opt(args, "--fast") is None {
    println("stress: need --gen, --brute and --fast \"CMD\"")
    return
  }
  let (gp, ga) = split_cmd(get_opt(args, "--gen").unwrap_or(""))
  let (bp, ba) = split_cmd(get_opt(args, "--brute").unwrap_or(""))
  let (fp, fa) = split_cmd(get_opt(args, "--fast").unwrap_or(""))
  let rounds = match parse_positive(get_opt(args, "--rounds").unwrap_or("100")) {
    Some(n) => n
    None => {
      println("stress: --rounds must be a positive integer")
      return
    }
  }
  let seed = parse_seed(get_opt(args, "--seed").unwrap_or("42"))
  let mode = parse_mode(get_opt(args, "--checker").unwrap_or("exact"))
  let timeout = match parse_positive(get_opt(args, "--timeout").unwrap_or("5000")) {
    Some(n) => n
    None => {
      println("stress: --timeout must be a positive integer")
      return
    }
  }
  let rng = @gen.Rng::new(seed)
  for i in 0..<rounds {
    let s = rng.next_u64()
    let gargs : Array[String] = []
    for x in ga {
      gargs.push(x)
    }
    gargs.push("\{s}")
    let gr = @runner.run(gp, gargs, timeout_ms=timeout)
    let input = gr.stdout
    let br = @runner.run(bp, ba, stdin=input, timeout_ms=timeout)
    let fr = @runner.run(fp, fa, stdin=input, timeout_ms=timeout)
    match @stress.compare(br.stdout, fr.stdout, mode) {
      Some(reason) => {
        let f : @stress.Failure = {
          round: i,
          seed: s,
          input,
          brute_out: br.stdout,
          fast_out: fr.stdout,
          reason,
        }
        println("Counterexample at round \{i} (seed=\{s}): \{reason}")
        save_failure(f)
        return
      }
      None => ()
    }
  }
  println("All \{rounds} rounds agree (seed=\{seed}).")
}

// ---- batch: judge a program over a directory of *.in / *.ans (or *.out) cases ----

///|
async fn batch_cli(args : Array[String]) -> Unit {
  let (p, a) = split_cmd(get_opt(args, "--prog").unwrap_or(""))
  let dir = get_opt(args, "--tests").unwrap_or("")
  let mode = parse_mode(get_opt(args, "--checker").unwrap_or("exact"))
  let timeout = match parse_positive(get_opt(args, "--timeout").unwrap_or("5000")) {
    Some(n) => n
    None => {
      println("batch: --timeout must be a positive integer")
      return
    }
  }
  if p == "" || dir == "" {
    println("batch: need --prog \"CMD\" and --tests DIR")
    return
  }
  let names = @fs.readdir(dir, sort=true)
  let mut total = 0
  let mut ac = 0
  for name in names {
    match name.strip_suffix(".in") {
      Some(base_view) => {
        total = total + 1
        let base = base_view.to_owned()
        let input = @fs.read_text(dir + "/" + name)
        let answer : String? = Some(@fs.read_text(dir + "/" + base + ".ans")) catch {
          _ => None
        }
        let answer = match answer {
          Some(a) => Some(a)
          None =>
            Some(@fs.read_text(dir + "/" + base + ".out")) catch {
              _ => None
            }
        }
        match answer {
          None => println("\{base}: CF (missing .ans/.out file)")
          Some(exp) => {
            let r = @runner.run(p, a, stdin=input, timeout_ms=timeout)
            let check : (String) -> Unit raise @checker.CheckError = out => {
              match @stress.compare(exp, out, mode) {
                Some(reason) => raise @checker.check_error(reason)
                None => ()
              }
            }
            let v = @runner.judge(r, check)
            match v {
              @checker.Verdict::AC => ac = ac + 1
              _ => ()
            }
            println("\{base}: \{verdict_string(v)}")
          }
        }
      }
      None => ()
    }
  }
  println("\{ac}/\{total} AC")
}
