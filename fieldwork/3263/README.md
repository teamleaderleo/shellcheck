# Fieldwork: synthetic export reads across Bats tests

Upstream issue: https://github.com/koalaman/shellcheck/issues/3263  
Inspected source: `9af7ee28ce587baadd950b85dd6826a16b9c068d`  
External contact: **not authorized and not performed**

## In simple words

Each Bats `@test` block is correctly treated as an isolated subshell. The false warning in the original report came from a narrower ordering bug: `export foo=value` was represented as both a reference and an assignment, and the synthetic reference was processed first. At the start of the second test, that artificial read saw the first test's dead `foo` before the replacement assignment made the new value alive.

The fork now fixes that original case without erasing real cross-test reads.

## Implemented correction

In `subshellAssignmentCheck`, ignore a `Reference` whose reference token is the same variable's `T_Assignment`. This suppresses only the artificial “exported variable is used externally” reference. A real RHS reference such as `export foo=$foo` has its own dollar-expansion token and remains eligible for SC2030/SC2031.

The implementation does not reset all variable state between Bats tests. Existing behavior intentionally warns when one test assigns a value and a later test genuinely reads it.

## Executed evidence

Workflow run `30836287359`, job `91762153657`, completed successfully on Ubuntu with GHC 9.6.6.

- full `cabal v2-test test-shellcheck` passed;
- the base literal-export fixture emitted SC2030 and SC2031;
- the candidate emitted neither diagnostic;
- `export foo=$foo` and `echo $foo` negative controls remained warning cases through the property suite;
- `git diff --check` passed.

Raw outputs and the receipt are retained under `fieldwork/3263/results/` and `fieldwork/3263/receipt.md`.

Evidence class: `target-executed` on one Linux/GHC configuration; not cross-platform or cross-version complete.

## Separate follow-up

The later issue comment involving a file sourced inside a Bats test is not the same mechanism. Included function bodies are linearly visited at the source site, so an assignment inside a sourced function can be marked dead when that test scope ends even though the function executes later. That needs a function/include control-flow model, not the narrow export fix.

The first retained attempt to characterize this follow-up was a harness failure: it ran from the repository root and stopped at SC1091 because `./lib.sh` did not resolve. A corrected control is executed from the fixture directory through Fieldwork Round 005 and must be evaluated separately.

## Artifacts

- `candidate.patch` records the original implementation sketch;
- `original.bats` and `resourced/` retain the two discriminating reports;
- `receipt.md` and `results/` retain executed primary-fix evidence.

## Disposition

**Primary original-case fix: implemented and target-executed.**  
**Sourced-function case: separate investigation; not claimed fixed.**
