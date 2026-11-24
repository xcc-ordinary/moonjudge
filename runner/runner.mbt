// Subprocess execution with timeout and output capture, plus verdict mapping.
// Built on the experimental core/async/shell package (native + wasm targets).

///|
/// The raw outcome of running a solution process.
pub struct RunResult {
  exit_code : Int32
  stdout : String
  stderr : String
  timed_out : Bool
}

///|
/// Run `program` with `args`, optionally feeding `stdin` text, capturing
/// stdout/stderr, and enforcing a wall-clock timeout (default 5000 ms).
/// A timeout (or execution failure) yields `timed_out = true`.
pub async fn run(
  program : String,
  args : ArrayView[String],
  stdin? : String,
  timeout_ms? : Int32,
) -> RunResult {
  let input = match stdin {
    Some(t) => @shell.Stdin::Text(t)
    None => @shell.Stdin::Inherit
  }
  let cmd = @shell.Cmd::Cmd(
    program,
    args,
    stdin=input,
    stdout=@shell.Redirect::Capture,
    stderr=@shell.Redirect::Capture,
  )
  let limit = timeout_ms.unwrap_or(5000)
  try {
    let out = cmd.output(timeout_ms=limit)
    {
      exit_code: out.exit_code(),
      stdout: out.stdout(),
      stderr: out.stderr(),
      timed_out: false,
    }
  } catch {
    _ =>
      {
        exit_code: -1,
        stdout: "",
        stderr: "timeout or execution error",
        timed_out: true,
      }
  }
}

///|
/// Map a raw run result to a verdict by applying a strict checker to stdout.
/// Timeout -> TLE; non-zero exit -> RE; checker failure -> WA; otherwise AC.
pub fn judge(
  result : RunResult,
  check : (String) -> Unit raise @checker.CheckError,
) -> @checker.Verdict {
  if result.timed_out {
    return @checker.Verdict::TLE
  }
  if result.exit_code != 0 {
    return @checker.Verdict::RE(
      "exit code \{result.exit_code}: \{result.stderr.trim()}",
    )
  }
  try {
    check(result.stdout)
    @checker.Verdict::AC
  } catch {
    @checker.CheckError(msg) => @checker.Verdict::WA(msg)
  }
}
