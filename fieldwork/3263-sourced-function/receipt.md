# Sourced-function control execution receipt

- Fieldwork workflow run: https://github.com/teamleaderleo/fieldwork/actions/runs/30839352175
- Job: `91772318148`
- Executed ShellCheck checkout head: `30358eeb89ae199c0371543e97318647cbd1c984`
- Runner: ubuntu-latest with GHC 9.6.6
- Invocation directory: the fixture directory, so `./lib.sh` resolved
- Exit status: `1`
- SC1091: absent
- SC2031: present for `COMPREPLY` at the later function call
- Output: `test.bats:16:8: note: COMPREPLY was modified in a subshell. That change might be lost. [SC2031]`

The fixture blobs on this branch match the executed primary-branch fixture blobs:

- `lib.sh`: `836ea664edad80cb26871aece9468ceeac72bf0f`
- `test.bats`: `6e21254f8880733570093fd46ed389f407d73e0a`

This establishes that the sourced-function case is a separate live control-flow false positive. It does not select a production fix.

Evidence class: `target-executed` focused control on one Linux/GHC configuration. No upstream contact.
