// Minimal probe: verify subprocess spawn + capture + timeout on Windows.
// Run with: moon run probe --target wasm  (or --target native with a C compiler)

///|
fn main {
  let cmd = @shell.Cmd::Cmd(
    "cmd.exe",
    ["/c", "echo moonjudge-probe-ok"],
    stdout=@shell.Redirect::Capture,
    stderr=@shell.Redirect::Capture,
  )
  let out = cmd.output(timeout_ms=5000)
  println("exit=\{out.exit_code()}")
  println("stdout=\{out.stdout().trim()}")
}
