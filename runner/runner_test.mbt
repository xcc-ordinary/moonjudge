// Cross-platform integration tests for the runner.
// Shell commands are chosen by OS so `moon test` passes on Windows and Linux.

///|
fn is_windows() -> Bool {
  match @env.get_env_var("OS") {
    Some(s) => s.contains("Windows")
    None => false
  }
}

///|
fn echo_cmd(text : String) -> (String, Array[String]) {
  if is_windows() {
    ("cmd.exe", ["/c", "echo " + text])
  } else {
    ("sh", ["-c", "echo " + text])
  }
}

///|
fn exit_cmd(code : Int32) -> (String, Array[String]) {
  if is_windows() {
    ("cmd.exe", ["/c", "exit \{code}"])
  } else {
    ("sh", ["-c", "exit \{code}"])
  }
}

///|
fn system32(name : String) -> String {
  let root = @env.get_env_var("SystemRoot").unwrap_or("C:\\Windows")
  root + "\\System32\\" + name
}

///|
fn sleep_cmd() -> (String, Array[String]) {
  if is_windows() {
    // Pure cmd.exe busy-loop (no external exe needed on a restricted PATH).
    ("cmd.exe", ["/c", "for /l %i in (1,1,100000000) do @rem"])
  } else {
    ("sh", ["-c", "sleep 5"])
  }
}

///|
async test "run captures stdout" {
  let (p, a) = echo_cmd("hello")
  let r = @runner.run(p, a)
  assert_eq(r.exit_code, 0)
  assert_eq(r.stdout.trim(), "hello")
  assert_eq(r.timed_out, false)
}

///|
async test "run captures non-zero exit" {
  let (p, a) = exit_cmd(3)
  let r = @runner.run(p, a)
  assert_eq(r.exit_code, 3)
  assert_eq(r.timed_out, false)
}

///|
async test "run feeds stdin" {
  let r = if is_windows() {
    @runner.run(system32("findstr.exe"), ["x"], stdin="x marks the spot")
  } else {
    @runner.run("sh", ["-c", "cat"], stdin="x marks the spot")
  }
  assert_eq(r.stdout.contains("marks"), true)
}

///|
async test "run enforces timeout" {
  let (p, a) = sleep_cmd()
  let r = @runner.run(p, a, timeout_ms=300)
  assert_eq(r.timed_out, true)
}

///|
async test "judge maps AC" {
  let (p, a) = echo_cmd("1 2 3")
  let r = @runner.run(p, a)
  let v = @runner.judge(r, out => @checkers.check_ints(out, 3))
  assert_eq(v, @checker.Verdict::AC)
}

///|
async test "judge maps WA on bad output" {
  let (p, a) = echo_cmd("1 2 x")
  let r = @runner.run(p, a)
  let v = @runner.judge(r, out => @checkers.check_ints(out, 3))
  match v {
    @checker.Verdict::WA(_) => ()
    _ => assert_eq(true, false)
  }
}

///|
async test "judge maps RE on non-zero exit" {
  let (p, a) = exit_cmd(2)
  let r = @runner.run(p, a)
  let v = @runner.judge(r, out => @checkers.check_ints(out, 1))
  match v {
    @checker.Verdict::RE(_) => ()
    _ => assert_eq(true, false)
  }
}

///|
async test "judge maps TLE on timeout" {
  let (p, a) = sleep_cmd()
  let r = @runner.run(p, a, timeout_ms=300)
  let v = @runner.judge(r, out => @checkers.check_ints(out, 1))
  assert_eq(v, @checker.Verdict::TLE)
}
