// Shared verdict types for the runner / CLI layer.

///|
/// The outcome of judging a single run.
#derive(Debug, Eq)
pub(all) enum Verdict {
  AC
  WA(String)
  TLE
  RE(String)
  /// Checker or infrastructure failure (not the solution's fault).
  CF(String)
}
