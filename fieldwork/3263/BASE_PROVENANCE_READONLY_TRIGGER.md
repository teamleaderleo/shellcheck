Temporary execution trigger for generation 2 of the exact-head, read-only ShellCheck 3263 repair.

Generation 1 tested a nonexistent simple-command reference base. Generation 2 skips only an assignment-token reference immediately followed by the matching command-owned assignment, and retains append, arithmetic, RHS, and bare-export reads.
