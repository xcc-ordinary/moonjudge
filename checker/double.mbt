// Strict floating-point reading (testlib readReal / readDouble style).

///|
/// Read a strict decimal floating-point token: optional sign, integer part
/// (no leading zeros), optional '.' + fraction digits, optional exponent.
/// Rejects negative zero. The token must be followed by whitespace or EOF.
pub fn InStream::read_double(self : InStream) -> Double raise CheckError {
  self.skip_space()
  let start = self.pos
  while self.pos < self.chars.length() &&
        !self.chars[self.pos].is_ascii_whitespace() {
    self.advance()
  }
  if self.pos == start {
    raise CheckError("expected double, found EOF")
  }
  let buf : Array[Char] = []
  for i in start..<self.pos {
    buf.push(self.chars[i])
  }
  let tok = String::from_array(buf)
  validate_double(tok)
  let v = @string.parse_double(tok) catch {
    _ => raise CheckError("invalid double: " + tok)
  }
  if v == 0.0 && buf.length() > 0 && buf[0] == '-' {
    raise CheckError("negative zero is not allowed")
  }
  v
}

///|
fn validate_double(tok : String) -> Unit raise CheckError {
  let cs = tok.to_array()
  let n = cs.length()
  let mut i = 0
  if i < n && (cs[i] == '+' || cs[i] == '-') {
    i = i + 1
  }
  let int_start = i
  while i < n && cs[i].is_ascii_digit() {
    i = i + 1
  }
  let int_len = i - int_start
  if int_len == 0 {
    raise CheckError("double requires integer digits")
  }
  if int_len > 1 && cs[int_start] == '0' {
    raise CheckError("leading zeros are not allowed")
  }
  if i < n && cs[i] == '.' {
    i = i + 1
    let frac_start = i
    while i < n && cs[i].is_ascii_digit() {
      i = i + 1
    }
    if i - frac_start == 0 {
      raise CheckError("double requires fraction digits after '.'")
    }
  }
  if i < n && (cs[i] == 'e' || cs[i] == 'E') {
    i = i + 1
    if i < n && (cs[i] == '+' || cs[i] == '-') {
      i = i + 1
    }
    let exp_start = i
    while i < n && cs[i].is_ascii_digit() {
      i = i + 1
    }
    if i - exp_start == 0 {
      raise CheckError("double requires exponent digits")
    }
  }
  if i != n {
    raise CheckError("invalid double format")
  }
}
