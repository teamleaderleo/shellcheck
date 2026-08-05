# ShellCheck 3263 execution receipts

## Initial literal-export candidate

- Workflow run: https://github.com/teamleaderleo/shellcheck/actions/runs/30836287359
- Starting head: `80aa4bb49bb2df4145e6cf78e85958de571c49d7`
- Runner: Ubuntu with GHC 9.6.6.
- Baseline: the literal-export Bats fixture emitted SC2030 and SC2031.
- Candidate: the literal-export fixture emitted neither diagnostic.
- Negative controls: real RHS and cross-test reads passed in the full `test-shellcheck` suite.
- Gates: full `cabal v2-test test-shellcheck`, focused CLI assertions, and `git diff --check`.
- Later self-review found an uncovered defect: the broad assignment-token filter also suppresses the genuine read in `export foo+=value`.

## Command-owned adjacency candidate — read-only

- Workflow run: https://github.com/teamleaderleo/shellcheck/actions/runs/30959236798
- Job: `92159247440`
- Immutable starting source: `a1716be3b847dc23761d35137b43cef7752b3c1d`
- Immutable transformer/control commit: `b6dbe06d033f67b472450b59cacd9175f8b6ef31`
- Runner: Ubuntu 24.04 with GHC 9.6.6.
- Full `cabal v2-test test-shellcheck --test-show-details=direct` passed.
- `exe:shellcheck` built successfully.
- Literal replacement export emitted no SC2030/SC2031.
- Append export retained SC2030 and SC2031.
- Bare export retained SC2030 and SC2031.
- The local diff was limited to `src/ShellCheck/Analytics.hs`; `git diff --check` passed.
- Evidence class: target-executed read-only on one Linux/GHC configuration.

## Materialization boundary

Execution PRs #8 and #9 attempted to publish the exact green candidate through restricted owned-repository workflows. No observable materialization run or canonical source update resulted. The normal build workflow was restored byte-for-byte, temporary workflows were deleted from `master`, and both execution branches were reset to the cleaned master head.

The canonical production source is **not** the green candidate and still has the known append-read defect. Do not claim implementation or publication from this receipt.

## Separate sourced-function fixture

The corrected sourced-function fixture is tracked separately. It retained SC2031 without SC1091 and is not claimed fixed here.

Upstream contact: unauthorized and absent.
