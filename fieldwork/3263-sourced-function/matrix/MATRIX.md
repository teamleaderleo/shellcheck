# Sourced-function discriminator matrix

These fixtures separate three competing causes of the focused SC2031 false positive:

- function-body traversal at definition/include time;
- repeated include token identity;
- flattening of Bats `setup()` and per-test execution into one source-order flow.

They are fixture-only artifacts. No ShellCheck result is recorded until an exact source head executes them from this directory.

| Fixture | Distinguishing question | Expected semantic boundary |
| --- | --- | --- |
| `setup-only.bats` | Is the redundant source inside the first test necessary? | A warning here removes repeated in-test sourcing as a prerequisite. |
| `independent-sources.bats` | Does each test sourcing the same library independently still inherit dead state? | The second source should define, not execute, the function body; later invocation should own the assignment. |
| `same-test.bats` | Does a source, call, and read in one Bats test remain clean? | The function body's real write and read occur in one test scope. |
| `different-paths.bats` | Does same content under a different include path change the result? | A difference from the primary same-path fixture points toward include/token identity. |
| `top-level-assignment.bats` | Are real sourced top-level writes still tracked across tests? | SC2030/SC2031 should remain for an actual assignment executed only in the first test. |
| `function-body-warning.bats` | Would a broad function-body exclusion hide ordinary diagnostics inside a real function body? | SC2086 on the unquoted `$1` must remain visible. |

## Runtime semantic control

`definition-isolation.bats` is **not** a ShellCheck undefined-function discriminator. A bare command name can always refer to an external executable, so ShellCheck cannot reliably diagnose the second-test `first_test_only` call merely because the function definition appears in another Bats test.

Its narrower role is to document the runtime Bats fact that test-local function definitions are isolated. If a runner has Bats available, execute this fixture with Bats and record the second test's runtime failure separately. Do not infer a ShellCheck static requirement from the absence of an undefined-function diagnostic.

## ShellCheck execution contract

Run the six static discriminator files above from this `matrix/` directory with the exact ShellCheck executable and retain complete output plus exit status.

Required classification:

1. record SC1091 separately; an unresolved include is a harness failure;
2. record SC2030 and SC2031 by file and line;
3. require SC2086 to remain in `function-body-warning.bats`; losing it rejects any broad function-body exclusion;
4. compare `different-paths.bats` with the primary same-path fixture;
5. keep the real top-level sourced assignment as a negative control against over-suppression;
6. do not infer Bats runtime correctness from a clean ShellCheck result;
7. do not select a production repair until the matrix distinguishes the owning mechanism.

If Bats itself is available, `definition-isolation.bats` may be run as an additional runtime semantic receipt, but that result is separate from the six-file ShellCheck matrix.
