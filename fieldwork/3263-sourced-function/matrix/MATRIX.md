# Sourced-function discriminator matrix

These fixtures separate three competing causes of the focused SC2031 false positive:

- function-body traversal at definition/include time;
- repeated include token identity;
- flattening of Bats `setup()` and per-test execution into one source-order flow.

They are fixture-only artifacts. No result is recorded until an exact ShellCheck head executes them from this directory.

| Fixture | Distinguishing question | Expected semantic boundary |
| --- | --- | --- |
| `setup-only.bats` | Is the redundant source inside the first test necessary? | A warning here removes repeated in-test sourcing as a prerequisite. |
| `independent-sources.bats` | Does each test sourcing the same library independently still inherit dead state? | The second source should define, not execute, the function body; later invocation should own the assignment. |
| `same-test.bats` | Does a source, call, and read in one Bats test remain clean? | The function body's real write and read occur in one test scope. |
| `different-paths.bats` | Does same content under a different include path change the result? | A difference from the primary same-path fixture points toward include/token identity. |
| `top-level-assignment.bats` | Are real sourced top-level writes still tracked across tests? | SC2030/SC2031 should remain for an actual assignment executed only in the first test. |
| `definition-isolation.bats` | Would a broad function-body exclusion hide an unavailable cross-test definition? | The second test cannot rely on a function defined only in the first isolated test. |

## Execution contract

Run each Bats file from this `matrix/` directory with the exact candidate ShellCheck executable and retain complete output plus exit status.

Required classification:

1. record SC1091 separately; an unresolved include is a harness failure;
2. record SC2030 and SC2031 by file and line;
3. record function-availability diagnostics for `definition-isolation.bats`;
4. compare `different-paths.bats` with the primary same-path fixture;
5. do not infer runtime correctness from a clean static result;
6. do not select a production repair until the matrix distinguishes the owning mechanism.
