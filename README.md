# moonjudge

[![CI](https://github.com/xcc-ordinary/moonjudge/actions/workflows/ci.yml/badge.svg)](https://github.com/xcc-ordinary/moonjudge/actions/workflows/ci.yml)

Local judge and stress-testing toolchain for MoonBit — a native reimplementation
of the strict checking semantics of [testlib.h](https://github.com/MikeMirzayanov/testlib)
(MIT, Codeforces), plus seeded data generation, a subprocess runner with timeout,
and a reproducible stress-testing ("对拍") CLI.

> 2026 MoonBit Hackathon entry · direction: developer tools · November season.
>
> 中文文档：[README.zh-CN.md](README.zh-CN.md)

## Why

Competitive programming training (CSP / ICPC / Codeforces) relies on stress testing
and strict output validation. MoonBit already has algorithm libraries
(`ac-library-mbt`, `moongraph`) but no local judging / verification tooling —
a scan of ~100 mooncakes keywords found zero projects for `testlib` or judging.
`moonjudge` fills that gap with a toolchain written natively in MoonBit.

## Features

- **`checker`** — strict streaming validation core (`InStream`): `read_int`
  (sign / leading-zero / negative-zero / overflow / bounds / token-boundary rules),
  `read_double` (strict decimal / exponent, rejects non-finite), `read_token`, `read_line`, `read_eof`,
  `ensure`; `CheckError` and `Verdict`
  (`AC` / `WA` / `TLE` / `RE` / `CF`) types.
- **`checkers`** — ready-made checkers: `check_ints`, `check_int_sequence`,
  `check_unordered_ints` (multiset), `check_permutation` (of 1..n), `check_yes_no`
  (case-insensitive), `check_token` (exact), `check_double` / `check_doubles` /
  `check_double_sequence` (absolute/relative tolerance, testlib-style),
  `check_sorted` (nondecreasing integer sequence), `check_unordered_doubles`
  (tolerance multiset), `check_tokens` (string sequence, optional case-insensitive).
- **`gen`** — seedable, reproducible `Rng` (xorshift64*) with `next_int(min, max)`,
  `next_array`, and `permutation` (Fisher-Yates).
- **`runner`** — async subprocess execution with stdin feed, stdout/stderr capture,
  timeout kill, and verdict mapping (`judge`; spawn failures map to RE, not TLE).
- **`stress`** — reproducible comparison loop (`stress_inprocess`) with four compare
  modes (`Exact` / `Ints` / `UnorderedInts` / `Doubles(eps)`); returns the first
  counterexample with its seed for exact replay.
- **`cmd/moonjudge`** — CLI with `demo`, `judge`, `stress`, and `batch` subcommands. `judge`
  validates format or, with `--answer FILE`, compares against a reference output
  (a real local judge). Persists counterexamples to `moonjudge-failure/` for replay.
- **`examples`** — dogfooding on real CSP-style problems: maximum subarray sum
  (all-negative Kadane bug) and lower_bound binary search (duplicate-element bug).

## Install from mooncakes

Published on [mooncakes.io](https://mooncakes.io) as `xcc-ordinary/moonjudge`:

```bash
moon add xcc-ordinary/moonjudge
```

Then import the packages you need, e.g. `xcc-ordinary/moonjudge/checkers`
(as `@checkers`) and `xcc-ordinary/moonjudge/stress`.

## Quickstart

```bash
moon test --target wasm          # full regression suite (87 tests)
moon test --target wasm-gc       # pure-logic packages (78 tests)

# Self-contained demo: catches a planted bug and saves the counterexample.
moon run --target wasm cmd/moonjudge -- demo

# Judge a solution: validate format, or compare against a reference answer.
moon run --target wasm cmd/moonjudge -- judge --prog "cmd.exe /c echo 42" --checker ints
moon run --target wasm cmd/moonjudge -- judge --prog "sol.exe" --answer ans.txt --checker doubles

# Stress-test external programs (generator receives the round seed as its last arg).
moon run --target wasm cmd/moonjudge -- stress \
  --gen "gen.exe" --brute "brute.exe" --fast "fast.exe" --rounds 100 --seed 42

# Batch-judge a program over a directory of cases (case.in + case.ans).
moon run --target wasm cmd/moonjudge -- batch --prog "sol.exe" --tests ./tests --checker ints
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
| `cmd/moonjudge` | CLI entry: `demo` / `judge` / `stress` / `batch` |
| `examples` | Dogfooding: real CSP-style problem stress cases |
| `probe` | Minimal subprocess capability probe |

## Verification

- **87 tests passing** on `wasm` (full suite), **78** on `wasm-gc` (pure logic).
- CI (GitHub Actions) runs check + full tests on every push and pull request.
- A deliberately-wrong regression corpus exercises every strict integer / double rule.
- The stress demo plants a real bug (`n % 7 == 0` off-by-one) and the loop catches it;
  the same seed reproduces the identical counterexample.
- Dogfooding on a real CSP-style problem catches a genuine algorithm bug (see below).
- Cross-platform integration tests select `cmd.exe` / `sh` by OS.

### Benchmark

Throughput (wasm-gc, debug build, `moon test checkers`):

```
check_int_sequence:    4000000 ints in ~0.15s   (~27 million integers / second)
check_unordered_ints:  30000 ints (reversed) in ~0.003s
```

The unordered path uses the builtin `Array::sort`, **~34x faster** than the
previous insertion sort on this worst-case (reversed) input.

## Dogfooding (real CSP-style problem)

`examples/max_subarray.mbt` stress-tests **maximum subarray sum**: an O(n²) brute
force against a Kadane implementation with the classic "initialize best to 0" bug.
moonjudge finds a real counterexample at round 0 (seed reproducible):

```
input = 2 -4 -2      (n = 2, array [-4, -2])
brute = -2           (correct: max subarray is the single element -2)
buggy = 0            (wrong: Kadane clamped to 0 on an all-negative array)
```

The corrected Kadane (best initialized to `a[0]`) passes all 2000 rounds. This is
the tool catching a bug a competitive programmer actually makes, not a toy mismatch.

A second case, `examples/lower_bound.mbt`, stress-tests **lower_bound** binary search
against a linear scan. The buggy version uses `a[mid] <= target` (computing upper_bound),
which is wrong whenever the target has duplicates:

```
input = 8 1 0 0 1 3 3 4 4 4   (n = 8, target = 1, sorted array)
brute = 2                     (correct lower_bound: first index with a[i] >= 1)
buggy = 3                     (wrong: upper_bound, first index with a[i] > 1)
```

The corrected binary search (`a[mid] < target`) passes all 2000 rounds.

## testlib semantics covered

Strict integer reading rejects: leading zeros (`007`), negative zero (`-0`),
out-of-range values, missing token boundaries, and trailing garbage after EOF —
matching testlib.h's `readInt` / `readLong` contract, reimplemented natively.

## Roadmap

- [x] **W1** — strict checker core, built-in checkers, seeded RNG, subprocess probe.
- [x] **W2** — `runner`: subprocess management, timeout kill, capture, verdict mapping.
- [x] **W3** — stress core + CLI (`demo` / `judge` / `stress`), counterexample persistence.
- [x] **W4** — throughput benchmark, full documentation, reproducible demo.
- [x] **Post-MVP** — double/tolerance checkers, `check_permutation` / `check_yes_no` /
  `check_token`, `judge --answer` reference comparison + `Doubles` mode, two real
  CSP-style dogfooding cases (`examples`).
- [x] mooncakes publication (`xcc-ordinary/moonjudge` 0.1.0).
- [x] **0.2.0** — `check_unordered_doubles` / `check_tokens`, `batch` directory
  judging, Chinese README.
- [x] **0.2.1** — reject non-finite doubles; distinguish spawn errors (RE) from
  timeouts (TLE); GitHub Actions CI.
- [x] **0.2.2** — CLI argument validation, per-seed counterexample archive,
  `batch` `*.out` fallback, CHANGELOG.
- [ ] Future: more validators.

## License & origin

MIT. Checker semantics are modeled on testlib.h (MIT); no testlib code is copied —
the rules are reimplemented natively in MoonBit. See `LICENSE`.

## AI usage

AI assisted code generation and API discovery. Goals, task decomposition, technical
choices, and final quality are owned and explainable by the participant; all development
is tracked through public commits.