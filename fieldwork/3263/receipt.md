# ShellCheck 3263 execution receipt

- Workflow run: https://github.com/teamleaderleo/shellcheck/actions/runs/30836287359
- Starting head: 80aa4bb49bb2df4145e6cf78e85958de571c49d7
- Runner: ubuntu-latest with GHC 9.6.6
- Baseline: the literal-export Bats fixture emitted SC2030 and SC2031.
- Candidate: the literal-export fixture emitted neither diagnostic.
- Negative controls: real RHS and cross-test reads are encoded as QuickCheck properties and passed in the full `test-shellcheck` suite.
- Separate sourced-function fixture: retained in `results/resourced.txt`; not claimed fixed.
- Gates: full `cabal v2-test test-shellcheck`, focused CLI baseline/candidate assertions, and `git diff --check`.
- Evidence class: target-executed test suite on one Linux/GHC configuration; not cross-version or platform-complete.
- Upstream contact: unauthorized and absent.
