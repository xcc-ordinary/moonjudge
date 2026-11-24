// Order-validation checker.

///|
/// Check the output is a nondecreasing strict integer sequence (any length).
pub fn check_sorted(output : String) -> Unit raise @checker.CheckError {
  let s = @checker.InStream::new(output)
  let mut prev : Int64? = None
  while true {
    s.skip_space()
    if s.eof() {
      break
    }
    let v = s.read_int()
    match prev {
      Some(p) =>
        if v < p {
          raise @checker.check_error("sequence is not nondecreasing")
        }
      None => ()
    }
    prev = Some(v)
  }
  s.read_eof()
}