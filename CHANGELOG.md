# Changelog

## 0.2.3
- CI: add an explicit `moon build --target wasm` step (check → build → test coverage).
- Docs: state the minimum toolchain version (`moonc` >= 0.10.16) in both READMEs.

## 0.2.2
- CLI: validate required commands and positive numeric options (clear errors instead of silent defaults).
- CLI: archive each counterexample under `moonjudge-failure/<seed>/` to preserve history.
- CLI: `batch` accepts `*.out` answer files as a fallback to `*.ans`.
- CI: bump `actions/checkout` to v5 (remove Node 20 deprecation warning).

## 0.2.1
- Fix: `read_double` rejects non-finite values (overflow to infinity).
- Fix: runner distinguishes timeouts (TLE) from spawn/execution errors (RE).
- CI: GitHub Actions runs check + tests (wasm, wasm-gc) on every push and PR.

## 0.2.0
- Add `check_unordered_doubles` (tolerance multiset) and `check_tokens` (string sequence).
- Add `batch` subcommand: judge a program over a directory of `*.in` / `*.ans` cases.
- Add Chinese README (`README.zh-CN.md`).

## 0.1.0
- Initial public release on mooncakes.
- Strict testlib-style checker core (`read_int` / `read_double` / `read_token` / `read_line`).
- Built-in checkers: ints, sequence, unordered, permutation, yes/no, token, doubles, sorted.
- Seeded reproducible RNG (`next_int`, `next_array`, `permutation`).
- Subprocess runner with timeout and verdict mapping; stress loop; CLI `demo` / `judge` / `stress`.
- Performance: builtin sort for unordered comparison (~34x on reversed input).