# Fieldwork: sourced function bodies across Bats tests

Upstream issue family: https://github.com/koalaman/shellcheck/issues/3263  
Inspected source base: `9af7ee28ce587baadd950b85dd6826a16b9c068d`  
External contact: **not authorized and not performed**

## In simple words

A library file defines a function that assigns an array. Bats `setup()` sources the library before each test, one test redundantly sources it again, and a later test calls the function. ShellCheck attributes the function-body assignment to an earlier test's subshell even though sourcing a function definition does not execute its body.

This is separate from the literal-`export` ordering bug fixed on clean source PR #11.

## Executed control

Fieldwork workflow run `30839352175`, job `91772318148`, executed the fixture from this directory on Ubuntu with GHC 9.6.6:

- `./lib.sh` resolved;
- ShellCheck exited 1;
- SC1091 was absent;
- SC2031 remained at the later `COMPREPLY` read;
- the branch fixture blobs match the executed fixture blobs.

This establishes a focused live control-flow false positive. It does not select a production fix.

## Source model

- includes are represented by `T_SourceCommand` and `T_Include`;
- the legacy `getVariableFlow` pass produces one linear event stream with `doStackAnalysis`;
- each `T_BatsTest` opens a `SubshellScope "@bats test"`;
- the linear traversal visits included descendants, including `T_Function` bodies, at the source site;
- `subshellAssignmentCheck` marks those writes dead when the earlier Bats scope ends;
- later function invocation is not represented as re-execution of the function body's writes in that linear model.

ShellCheck's CFG already distinguishes function definition from execution through `CFDefineFunction` and separate function execution graphs. The likely owning boundary is therefore function/include execution modeling or a CFG-backed replacement for SC2030/SC2031—not another token-specific exception.

## Competing hypotheses

1. definition-time traversal treats the function body as executed when the file is sourced;
2. repeated include token identity leaks state between source sites;
3. Bats `setup()` lifecycle is under-modeled, so its per-test execution is flattened into one source-order stream.

The executed fixture proves the false positive survives after include resolution. It does not yet distinguish all three mechanisms.

## Static discriminator controls

The prepared ShellCheck matrix now contains six static controls:

- `setup-only.bats`: setup sources the library, later test calls the function, with no redundant first-test source;
- `independent-sources.bats`: each test sources independently;
- `same-test.bats`: source, call, and read remain in one test;
- `different-paths.bats`: identical library content arrives through two include paths;
- `top-level-assignment.bats`: a real sourced top-level write must keep cross-test SC2030/SC2031 behavior;
- `function-body-warning.bats`: an ordinary function body contains a deliberate SC2086 control, proving that a repair must not broadly stop analysing function bodies.

The previous `definition-isolation.bats` idea was overclaimed as a ShellCheck discriminator. ShellCheck cannot reliably call a bare command undefined because it may be an external executable. That fixture is retained only as a Bats runtime semantic control: a function defined in one isolated test is not available in another. If Bats is executed, that result must be recorded separately from ShellCheck diagnostics.

## Candidate architectures

Compare:

1. a CFG-backed SC2030/SC2031 analysis with function calls and subshell boundaries;
2. explicit legacy flow events for function definition versus modeled invocation;
3. a bounded definition-time exclusion only if call-site modeling preserves existing function diagnostics.

Simply skipping all function bodies is unsafe. The new SC2086 fixture makes that rejection executable rather than merely conceptual.

## Current state

Evidence class: `target-executed-focused`, `source-reviewed`, `production-fix-not-selected`.

The six-file static discriminator matrix is prepared but unexecuted. `definition-isolation.bats` is runtime-only supplemental context. No production source change is justified until the static matrix identifies the owning semantic boundary and any proposed repair preserves the function-body warning and top-level assignment controls.
