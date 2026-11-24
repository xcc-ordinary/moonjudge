// Black-box regression tests for the strict checker core.
// Includes deliberately wrong outputs (WA / format errors) as a regression corpus.

///|
fn raised(action : () -> Unit raise @checker.CheckError) -> Bool {
  try {
    action()
    false
  } catch {
    @checker.CheckError(_) => true
  }
}

///|
test "read_int basic" {
  let s = @checker.InStream::new("42")
  assert_eq(s.read_int(), 42L)
}

///|
test "read_int signed with bounds" {
  let s = @checker.InStream::new("-7 100")
  assert_eq(s.read_int(min=-10L, max=10L), -7L)
  assert_eq(s.read_int(), 100L)
}

///|
test "read_int plus sign and zero" {
  let s = @checker.InStream::new("+5 0")
  assert_eq(s.read_int(), 5L)
  assert_eq(s.read_int(), 0L)
}

///|
test "read_int rejects leading zero" {
  let s = @checker.InStream::new("007")
  assert_eq(
    raised(() => {
      let _ = s.read_int()
      ()
    }),
    true,
  )
}

///|
test "read_int rejects negative zero" {
  let s = @checker.InStream::new("-0")
  assert_eq(
    raised(() => {
      let _ = s.read_int()
      ()
    }),
    true,
  )
}

///|
test "read_int rejects empty" {
  let s = @checker.InStream::new("   ")
  assert_eq(
    raised(() => {
      let _ = s.read_int()
      ()
    }),
    true,
  )
}

///|
test "read_int rejects trailing garbage" {
  let s = @checker.InStream::new("12x")
  assert_eq(
    raised(() => {
      let _ = s.read_int()
      ()
    }),
    true,
  )
}

///|
test "read_int rejects out of bounds" {
  let s = @checker.InStream::new("101")
  assert_eq(
    raised(() => {
      let _ = s.read_int(min=0L, max=100L)
      ()
    }),
    true,
  )
}

///|
test "read_int rejects overflow" {
  let s = @checker.InStream::new("99999999999999999999999")
  assert_eq(
    raised(() => {
      let _ = s.read_int()
      ()
    }),
    true,
  )
}

///|
test "read_token skips whitespace" {
  let s = @checker.InStream::new("  hello\tworld\n")
  assert_eq(s.read_token(), "hello")
  assert_eq(s.read_token(), "world")
}

///|
test "read_token rejects EOF" {
  let s = @checker.InStream::new("   ")
  assert_eq(
    raised(() => {
      let _ = s.read_token()
      ()
    }),
    true,
  )
}

///|
test "read_line strips crlf" {
  let s = @checker.InStream::new("first\r\nsecond\n")
  assert_eq(s.read_line(), "first")
  assert_eq(s.read_line(), "second")
}

///|
test "read_eof accepts trailing whitespace" {
  let s = @checker.InStream::new("1 \n\t")
  let _ = s.read_int()
  s.read_eof()
}

///|
test "read_eof rejects trailing content" {
  let s = @checker.InStream::new("1 2")
  let _ = s.read_int()
  assert_eq(raised(() => s.read_eof()), true)
}

///|
test "ensure fails with message" {
  let s = @checker.InStream::new("")
  assert_eq(raised(() => s.ensure(false, "boom")), true)
  s.ensure(true, "ok")
}
