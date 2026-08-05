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

Evidence class: `target-executed-focused`, `source-reviewed`, `production-fix-not-selected`.

Next work is a discriminator matrix that separates definition-time traversal, repeated-include identity, and Bats `setup()` flattening. No production source change is justified until that matrix identifies the owning semantic boundary.
