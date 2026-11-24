// Strict streaming input validation for judged output.
// Semantics modeled on testlib.h (MIT License, Codeforces):
// https://github.com/MikeMirzayanov/testlib

///|
/// Raised when the judged output violates the expected format or bounds.
/// Carries a human-readable reason, analogous to testlib's `fail` / `ensuref`.
pub suberror CheckError {
  CheckError(String)
}

///|
/// Public constructor so other packages can raise a CheckError
/// (suberror constructors are read-only across package boundaries).
pub fn check_error(msg : String) -> CheckError {
  CheckError(msg)
}

///|
/// A cursor over the judged output, read character by character under strict
/// format rules. Positions are counted in characters (not UTF-16 code units).
pub struct InStream {
  chars : Array[Char]
  mut pos : Int32
}

///|
/// Wrap a judged output string into a strict input stream.
pub fn InStream::new(text : String) -> InStream {
  { chars: text.to_array(), pos: 0, }
}

///|
fn InStream::peek(self : InStream) -> Char? {
  if self.pos < self.chars.length() {
    Some(self.chars[self.pos])
  } else {
    None
  }
}

///|
fn InStream::advance(self : InStream) -> Unit {
  self.pos = self.pos + 1
}

///|
/// Whether the cursor has reached the end of the output.
pub fn InStream::eof(self : InStream) -> Bool {
  self.pos >= self.chars.length()
}

///|
/// Skip ASCII whitespace (space, \t, \n, \v, \f, \r), testlib-style.
pub fn InStream::skip_space(self : InStream) -> Unit {
  while self.pos < self.chars.length() &&
        self.chars[self.pos].is_ascii_whitespace() {
    self.pos = self.pos + 1
  }
}

///|
/// Assert a condition, otherwise fail with `msg` (testlib `ensuref`).
pub fn InStream::ensure(
  _self : InStream,
  cond : Bool,
  msg : String,
) -> Unit raise CheckError {
  if !cond {
    raise CheckError(msg)
  }
}

///|
/// Read a signed integer token with strict rules:
/// optional `+`/`-`, at least one digit, no leading zeros, no `-0`,
/// optional inclusive `[min, max]` bounds, and the token must be followed
/// by whitespace or EOF. Accumulation is guarded against Int64 overflow.
pub fn InStream::read_int(
  self : InStream,
  min? : Int64,
  max? : Int64,
) -> Int64 raise CheckError {
  self.skip_space()
  let mut neg = false
  match self.peek() {
    None => raise CheckError("expected integer, found EOF")
    Some(c) =>
      if c == '-' || c == '+' {
        neg = c == '-'
        self.advance()
      }
  }
  let mut value : Int64 = 0L
  let mut digits = 0
  let mut first_digit : Char = '0'
  while true {
    match self.peek() {
      Some(c) if c.is_ascii_digit() => {
        if digits == 0 {
          first_digit = c
        }
        if value > 922337203685477580L {
          raise CheckError("integer overflow")
        }
        value = value * 10L + (c.to_int() - 48).to_int64()
        digits = digits + 1
        self.advance()
      }
      _ => break
    }
  }
  if digits == 0 {
    raise CheckError("expected integer digits")
  }
  if digits > 1 && first_digit == '0' {
    raise CheckError("leading zeros are not allowed")
  }
  if neg {
    value = -value
  }
  if neg && value == 0L {
    raise CheckError("negative zero is not allowed")
  }
  match self.peek() {
    Some(c) if !c.is_ascii_whitespace() =>
      raise CheckError("integer must be followed by whitespace or EOF")
    _ => ()
  }
  match min {
    Some(lo) =>
      if value < lo {
        raise CheckError("integer \{value} below minimum \{lo}")
      }
    None => ()
  }
  match max {
    Some(hi) =>
      if value > hi {
        raise CheckError("integer \{value} above maximum \{hi}")
      }
    None => ()
  }
  value
}

///|
/// Read a non-empty whitespace-delimited token (testlib `readToken`).
pub fn InStream::read_token(self : InStream) -> String raise CheckError {
  self.skip_space()
  let start = self.pos
  while self.pos < self.chars.length() &&
        !self.chars[self.pos].is_ascii_whitespace() {
    self.advance()
  }
  if self.pos == start {
    raise CheckError("expected token, found EOF")
  }
  let buf : Array[Char] = []
  for i in start..<self.pos {
    buf.push(self.chars[i])
  }
  String::from_array(buf)
}

///|
/// Read a single line up to `\n`, stripping `\r` (testlib `readLine`).
pub fn InStream::read_line(self : InStream) -> String raise CheckError {
  if self.eof() {
    raise CheckError("expected line, found EOF")
  }
  let buf : Array[Char] = []
  while self.pos < self.chars.length() {
    let c = self.chars[self.pos]
    self.advance()
    if c == '\n' {
      break
    }
    if c != '\r' {
      buf.push(c)
    }
  }
  String::from_array(buf)
}

///|
/// Require that only whitespace remains before EOF (testlib `readEof`).
pub fn InStream::read_eof(self : InStream) -> Unit raise CheckError {
  self.skip_space()
  if !self.eof() {
    raise CheckError("expected EOF, found trailing content")
  }
}
