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
