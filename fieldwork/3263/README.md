# Fieldwork: synthetic export reads across Bats tests

Upstream issue: https://github.com/koalaman/shellcheck/issues/3263  
Inspected source: `9af7ee28ce587baadd950b85dd6826a16b9c068d`  
External contact: **not authorized and not performed**

## In simple words

Each Bats `@test` block is correctly treated as an isolated subshell. The false warning in the original report comes from a narrower ordering bug: `export foo=value` is represented as both a reference and an assignment, and the synthetic reference is processed first. At the start of the second test, that synthetic reference sees the first test's dead `foo` before the replacement assignment makes the new value alive.

## Safe correction

In `subshellAssignmentCheck`, ignore a `Reference` whose reference token is the same variable's `T_Assignment`. This suppresses only the artificial “exported variable is used externally” reference. A real RHS reference such as `export foo=$foo` has its own dollar-expansion token and remains eligible for SC2030/SC2031.

Do not reset all variable state between Bats tests. Existing coverage intentionally warns when one test assigns a value and a later test reads it.

## Required controls

- two tests each running `export foo=<literal>`: no SC2030/SC2031;
- first test assigns `foo`, second test runs `export foo=$foo`: warning retained;
- first test assigns `foo`, second test echoes it: warning retained;
- ordinary pipeline/subshell assignment warnings unchanged;
- unused/export analysis unchanged, because the synthetic reference remains in general variable flow and is ignored only by this check.

## Separate follow-up

The later issue comment involving a file sourced inside a Bats test is not the same mechanism. Included function bodies are linearly visited at the source site, so an assignment inside a sourced function can be marked dead when that test scope ends even though the function executes later. That needs a function/include control-flow model, not the narrow export fix. It is retained as a distinct failing probe and must not be claimed fixed by this candidate.

## Artifacts

- `candidate.patch` contains the narrow analyzer change and property tests.
- `original.bats` and `resourced/` retain the two discriminating reports.

## Evidence state

`source-reviewed`; `target-test-prepared`; not executed in this environment. Promote only after the focused QuickCheck properties and ShellCheck's analyzer suite pass on the fork.