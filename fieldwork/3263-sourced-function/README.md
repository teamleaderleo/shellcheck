# Fieldwork: sourced function bodies across Bats tests

Upstream issue family: https://github.com/koalaman/shellcheck/issues/3263  
Inspected source base: `9af7ee28ce587baadd950b85dd6826a16b9c068d`  
External contact: **not authorized and not performed**

## In simple words

A library file defines a function that assigns an array. Bats `setup()` sources the library before each test, one test redundantly sources it again, and a later test calls the function. ShellCheck can attribute the function-body assignment to the earlier test's subshell even though sourcing a function definition does not execute its body.

This is separate from the literal-`export` ordering bug fixed on `fieldwork/3263-bats-synthetic-export-read`.

## Source model

- includes are represented by `T_SourceCommand` and `T_Include`;
- the legacy `getVariableFlow` pass produces one linear event stream with `doStackAnalysis`;
- each `T_BatsTest` opens a `SubshellScope "@bats test"`;
- the linear traversal visits included descendants, including `T_Function` bodies, at the source site;
- `subshellAssignmentCheck` marks those writes dead when the earlier Bats scope ends;
- later function invocation is not represented as re-execution of the function body's writes in that linear model.

ShellCheck's CFG already has a more appropriate distinction through `CFDefineFunction` and separate function execution graphs. The likely owning boundary is therefore function/include execution modeling or a CFG-backed replacement for SC2030/SC2031—not another token-specific exception.

## Competing hypotheses

1. definition-time traversal treats the function body as executed when the file is sourced;
2. repeated include token identity leaks state between source sites;
3. Bats `setup()` lifecycle is under-modeled, so its per-test execution is flattened into one source-order stream.

## Required controls

- `setup()` sources the library and a later test calls the function: no false warning;
- a first test redundantly sources the library and a later test calls the function: reproduce SC2031 without SC1091;
- a sourced file with a top-level assignment: preserve real subshell-local behavior;
- a function defined and called in one test: no lost-change warning for reads in that test;
- the library sourced independently for each test: no state inherited from an earlier test;
- a function defined only in the first test and called in the second: do not hide the unavailable-definition problem;
- nested and same-content/different-path includes: distinguish execution semantics from token identity.

## Candidate architectures

Compare:

1. a CFG-backed SC2030/SC2031 analysis with function calls and subshell boundaries;
2. explicit legacy flow events for function definition versus modeled invocation;
3. a bounded definition-time exclusion only if call-site modeling preserves existing function diagnostics.

Simply skipping all function bodies is unsafe because it would remove legitimate warnings when functions are invoked.

## Current state

The first retained run from the primary branch was a harness failure: it ran from the repository root and stopped at SC1091 because `./lib.sh` did not resolve. The corrected control must execute from this fixture directory and establish whether SC2031 remains after the include resolves.

Evidence state: `source-reviewed`; target control queued through Fieldwork Round 005; no production fix selected.
