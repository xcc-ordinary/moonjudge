// Throughput measurement for the strict integer-sequence checker.
// Run with: moon test --target wasm-gc checkers  (prints elapsed time)

///|
test "throughput: check_int_sequence 20000 ints x200" {
  let parts : Array[String] = []
  for i in 0..<20000 {
    parts.push("\{i}")
  }
  let input = parts.join(" ")
  let start = @bench.monotonic_clock_start()
  for _ in 0..<200 {
    @checkers.check_int_sequence(input) catch {
      _ => ()
    }
  }
  let elapsed_us = @bench.monotonic_clock_end(start)
  let elapsed_s = elapsed_us / 1000000.0
  println("check_int_sequence: 4000000 ints in \{elapsed_s}s")
}

///|
test "throughput: check_unordered_ints 3000 ints x10" {
  let exp : Array[Int64] = []
  let parts : Array[String] = []
  for i in 0..<3000 {
    exp.push(i.to_int64())
    parts.push("\{2999 - i}")
  }
  let input = parts.join(" ")
  let start = @bench.monotonic_clock_start()
  for _ in 0..<10 {
    @checkers.check_unordered_ints(input, exp) catch { _ => () }
  }
  let elapsed_us = @bench.monotonic_clock_end(start)
  println("check_unordered_ints: 30000 ints (reversed) in \{elapsed_us / 1000000.0}s")
}
