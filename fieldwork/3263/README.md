# Fieldwork: synthetic export reads across Bats tests

Upstream issue: https://redirect.github.com/koalaman/shellcheck/issues/3263  
Inspected source: `9af7ee28ce587baadd950b85dd6826a16b9c068d`  
Current canonical investigation head before this documentation update: `a1716be3b847dc23761d35137b43cef7752b3c1d`  
External contact: **not authorized and not performed**

## In simple words

Each Bats `@test` block is correctly treated as an isolated subshell. The false warning in the original report comes from a narrower ordering bug: replacement forms such as `export foo=value` contribute a command-level reference immediately before their assignment. At the start of a later test, that artificial read can observe the earlier test's dead value before the replacement assignment makes the new value alive.

The first fork implementation ignored every same-name assignment-token reference. That fixed the literal replacement case, but self-review found that it also erased the genuine read from append assignments such as `export foo+=value`. The source currently retained on this branch is therefore **not ready**.

## Tested replacement candidate

The command-owned adjacency candidate skips a reference only when:

1. the reference token is a shell assignment token;
2. the immediately following flow event is the matching assignment;
3. that assignment belongs to an `export` or `declare` simple command.

This matches the observed flow distinctions:

- replacement export: skip the artificial reference;
- append export: retain the earlier genuine append read and skip only the later artificial reference;
- arithmetic update: retain the read because the assignment is not command-owned;
- bare `export foo`: retain the read because its token is not an assignment;
- explicit RHS read: retain the separate expansion reference.

## Executed evidence

Initial workflow run `30836287359`, job `91762153657`, proved the original literal case and complete suite on Ubuntu/GHC 9.6.6, but did not include the later append discriminator.

Read-only workflow run `30959236798`, job `92159247440`, tested the replacement candidate against immutable source `a1716be3b847dc23761d35137b43cef7752b3c1d`:

- full `cabal v2-test test-shellcheck --test-show-details=direct` passed;
- `exe:shellcheck` built successfully;
- literal replacement export emitted no SC2030/SC2031;
- append export retained SC2030 and SC2031;
- bare export retained SC2030 and SC2031;
- the source diff was limited to `src/ShellCheck/Analytics.hs` and `git diff --check` passed.

Evidence class: `target-executed-read-only` on Ubuntu 24.04 with GHC 9.6.6; not cross-platform or cross-version complete.

## Publication boundary

Several execution-only carriers attempted to materialize the green candidate onto this canonical branch. GitHub emitted no observable materialization run or source update. Those carriers were retired, both temporary workflows were deleted from `master`, the normal build workflow was restored byte-for-byte, and the execution branches were reset to the cleaned master head.

Do not describe the green candidate as implemented on this branch. The canonical production file still contains the earlier broad assignment-token filter with the known append-read defect.

## Separate sourced-function follow-up

The issue comment involving a file sourced inside a Bats test is a separate mechanism. The corrected fixture was executed from its own directory and retained SC2031 without SC1091. Included function bodies are linearly visited at the source site, while their later call behavior is represented separately; a repair likely needs function/include control-flow modeling rather than the narrow export discriminator. That investigation remains in separate draft PR #3 with no production fix selected.

## Artifacts

- `candidate.patch` records the currently retained, superseded implementation and must not be treated as final;
- `original.bats` and `resourced/` retain discriminating reports;
- `receipt.md` and `results/` retain executed evidence;
- immutable carrier commit `b6dbe06d033f67b472450b59cacd9175f8b6ef31` retains the exact green transformer and controls.

## Disposition

**Primary candidate: full focused gate passed read-only; canonical source not materialized.**  
**Current retained source: known append-read defect; hold.**  
**Sourced-function case: separate reproduction-only investigation; not fixed.**
