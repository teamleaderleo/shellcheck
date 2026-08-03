# ShellCheck 3263 follow-up: sourced function bodies across Bats tests

Upstream report family: https://github.com/koalaman/shellcheck/issues/3263  
Inspected fork branch: `fieldwork/3263-bats-synthetic-export-read`  
External contact: **not authorized and not performed**

## In simple words

The original literal-`export` false positive is fixed. A later reproducer in the same issue is different: a library file is sourced more than once, one of its functions assigns an array, and a later Bats test calls that function. ShellCheck can attribute the function-body assignment to the earlier test's subshell even though a function definition does not execute its body when it is sourced.

This is an execution-model problem, not another synthetic-reference ordering problem.

## Source model

- Parsed includes are represented by `T_SourceCommand` and `T_Include` nodes.
- `getVariableFlow` builds a linear event stream with `doStackAnalysis`.
- A `T_BatsTest` opens a `SubshellScope "@bats test"`.
- The linear traversal visits descendants of an included AST in source order, including descendants of `T_Function` definitions.
- `subshellAssignmentCheck` consumes this linear stream and marks assignments dead when the surrounding Bats scope ends.
- The later function invocation is not represented as re-execution of the function body's variable events in this linear model.

ShellCheck's CFG has a more suitable distinction: `CFDefineFunction` records a disjoint function body, and command execution can invoke that body. The sourced-function defect therefore belongs near function/include execution modeling or a future CFG-backed replacement for SC2030/SC2031—not in the narrow export-token filter.

## Competing hypotheses

1. **Definition-time traversal is the cause.** The assignment inside the sourced function is treated as if it ran when the file was sourced inside the first Bats test.
2. **Repeated include identity is the cause.** Reusing the same included AST or token identities across source sites allows state from one Bats test to leak into another.
3. **Setup invocation is under-modeled.** Bats `setup()` is defined once but executed before each test; linear flow cannot represent that lifecycle and therefore assigns source effects to the wrong test generation.

The first correct execution control must distinguish these rather than merely suppressing SC2031.

## Required controls

- `setup()` sources the library; a later test calls the function: no false warning.
- the first test redundantly sources the same library; a later test calls the function: reproduce the reported warning without SC1091.
- a sourced file with a top-level assignment, rather than a function-body assignment: preserve the real subshell-local warning where appropriate.
- a function defined and called inside one Bats test: no lost-change warning for a read inside that same test.
- a function sourced independently for each test and called only in the later test: no state inherited from the earlier test.
- a function defined only in the first test and called in the second: do not hide the unavailable-definition problem.
- nested source files and two distinct source paths with identical content: separate token identity from semantic include identity.

## Candidate architecture

Do not add another name- or token-specific exception to `findSubshelled`.

Preferred directions to compare:

1. make SC2030/SC2031 consume CFG-backed write/read reachability, including function definitions, calls, and subshell boundaries;
2. introduce explicit linear-flow events for function definition versus function execution, then emit body events only at modeled call sites;
3. as a bounded intermediate, exclude function-body assignments from definition-time linear flow only if invocation modeling can preserve existing function diagnostics.

The third direction is unsafe without call-site controls: simply skipping function bodies would remove legitimate warnings for functions that are actually invoked.

## Current evidence

- primary literal-export fix: target-executed and green;
- first sourced-function run: harness failure, because it ran from the repository root and stopped at SC1091;
- corrected run: queued through Fieldwork Round 005 from the fixture directory;
- source mechanism: source-reviewed;
- production fix for this follow-up: **not selected**.

## Disposition

Retain as a separate investigation. Promote only after the corrected fixture reproduces SC2031 without SC1091 and the controls identify whether definition traversal, include identity, or Bats setup lifecycle owns the false state transition.
