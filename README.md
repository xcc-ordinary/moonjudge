# moonjudge

Local judge and stress-testing toolchain for MoonBit — a native reimplementation
of the strict checking semantics of [testlib.h](https://github.com/MikeMirzayanov/testlib)
(MIT, Codeforces), plus seeded data generation, a subprocess runner with timeout,
and a reproducible stress-testing ("对拍") CLI.

> 2026 MoonBit Hackathon entry · direction: developer tools · November season.

## Why

Competitive programming training (CSP / ICPC / Codeforces) relies on stress testing
and strict output validation. MoonBit already has algorithm libraries
(`ac-library-mbt`, `moongraph`) but no local judging / verification tooling —
a scan of ~100 mooncakes keywords found zero projects for `testlib` or judging.
`moonjudge` fills that gap with a toolchain written natively in MoonBit.

## Features

- **`checker`** — strict streaming validation core (`InStream`): `read_int`
  (sign / leading-zero / negative-zero / overflow / bounds / token-boundary rules),
  `read_token`, `read_line`, `read_eof`, `ensure`; `CheckError` and `Verdict`
  (`AC` / `WA` / `TLE` / `RE` / `CF`) types.
- **`checkers`** — ready-made checkers: `check_ints`, `check_int_sequence`
  (any-length strict integer sequence), `check_unordered_ints` (multiset / permutation).
- **`gen`** — seedable, reproducible `Rng` (xorshift64*) with `next_int(min, max)`.
- **`runner`** — async subprocess execution with stdin feed, stdout/stderr capture,
  timeout kill, and verdict mapping (`judge`).
- **`stress`** — reproducible comparison loop (`stress_inprocess`) with three compare
  modes (`Exact` / `Ints` / `UnorderedInts`); returns the first counterexample with
  its seed for exact replay.
- **`cmd/moonjudge`** — CLI with `demo`, `judge`, and `stress` subcommands; persists
  counterexamples to `moonjudge-failure/` for replay.

## Quickstart

```bash
moon test --target wasm          # full regression suite (44 tests)
moon test --target wasm-gc       # pure-logic packages (36 tests)

# Self-contained demo: catches a planted bug and saves the counterexample.
moon run --target wasm cmd/moonjudge -- demo

# Judge a solution's output.
moon run --target wasm cmd/moonjudge -- judge --prog "cmd.exe /c echo 42" --checker ints

# Stress-test external programs (generator receives the round seed as its last arg).
moon run --target wasm cmd/moonjudge -- stress \
  --gen "gen.exe" --brute "brute.exe" --fast "fast.exe" --rounds 100 --seed 42
```

The `wasm` target runs out of the box through `moonrun` and spawns real OS processes —
no C compiler required. The `native` target is also supported but needs a system C
compiler (`cc` / `gcc` / `clang`) to build the runtime.

### Demo output

```
Stress demo: sum 1..n, buggy fast solution (wrong when n % 7 == 0).
Counterexample at round 0 (seed=6255019084209693600):
  input = 0
  brute = 0
  fast  = -1
  reason= exact mismatch
Saved counterexample to moonjudge-failure/ (replay with the seed).
```

## Architecture

| Package | Responsibility |
|---|---|
| `checker` | Strict format/bounds validation core (testlib-style), error + verdict types |
| `checkers` | Ready-made checkers composed from the core |
| `gen` | Reproducible test-data generation |
| `runner` | Subprocess execution, timeout, capture, verdict mapping |
| `stress` | Reproducible brute-vs-fast comparison loop + counterexample capture |
| `cmd/moonjudge` | CLI entry: `demo` / `judge` / `stress` |
| `probe` | Minimal subprocess capability probe |

## Verification

- **44 tests passing** on `wasm` (full suite), **36** on `wasm-gc` (pure logic).
- A deliberately-wrong regression corpus exercises every strict integer rule.
- The stress demo plants a real bug (`n % 7 == 0` off-by-one) and the loop catches it;
  the same seed reproduces the identical counterexample.
- Cross-platform integration tests select `cmd.exe` / `sh` by OS.

### Benchmark

`check_int_sequence` throughput (wasm-gc, debug build, `moon test checkers`):

```
check_int_sequence: 4000000 ints in 0.128s   (~31 million integers / second)
```

## testlib semantics covered

Strict integer reading rejects: leading zeros (`007`), negative zero (`-0`),
out-of-range values, missing token boundaries, and trailing garbage after EOF —
matching testlib.h's `readInt` / `readLong` contract, reimplemented natively.

## Roadmap

- [x] **W1** — strict checker core, built-in checkers, seeded RNG, subprocess probe.
- [x] **W2** — `runner`: subprocess management, timeout kill, capture, verdict mapping.
- [x] **W3** — stress core + CLI (`demo` / `judge` / `stress`), counterexample persistence.
- [x] **W4** — throughput benchmark, full documentation, reproducible demo.
- [ ] Future: double/tolerance checkers, more built-in validators, mooncakes publication.

## License & origin

MIT. Checker semantics are modeled on testlib.h (MIT); no testlib code is copied —
the rules are reimplemented natively in MoonBit. See `LICENSE`.

## AI usage

AI assisted code generation and API discovery. Goals, task decomposition, technical
choices, and final quality are owned and explainable by the participant; all development
is tracked through public commits.