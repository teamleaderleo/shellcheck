#!/usr/bin/env python3
"""Apply the read-only ShellCheck 3263 command-owned-reference candidate."""

from __future__ import annotations

from pathlib import Path
import sys


def replace_exact(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected one site, found {count}")
    return text.replace(old, new, 1)


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: apply_command_owned_reference.py SHELLCHECK_ROOT")

    path = Path(sys.argv[1]).resolve() / "src/ShellCheck/Analytics.hs"
    text = path.read_text(encoding="utf-8")

    old_properties = '''prop_subshellAssignmentCheck28 = verifyTree subshellAssignmentCheck "@test 'one' { foo=bar; }\\n@test 'two' { echo $foo; }\\n"
subshellAssignmentCheck params t ='''
    new_properties = '''prop_subshellAssignmentCheck28 = verifyTree subshellAssignmentCheck "@test 'one' { foo=bar; }\\n@test 'two' { echo $foo; }\\n"
prop_subshellAssignmentCheck29 = verifyTree subshellAssignmentCheck "@test 'one' { foo=bar; }\\n@test 'two' { export foo+=baz; }\\n"
prop_subshellAssignmentCheck30 = verifyTree subshellAssignmentCheck "@test 'one' { foo=bar; }\\n@test 'two' { export foo; }\\n"
subshellAssignmentCheck params t ='''
    text = replace_exact(text, old_properties, new_properties, "property block")

    old_analysis = '''findSubshelled (Reference (_, readToken, str):rest) scopes deadVars = do
    unless (shouldIgnore readToken str) $ case Map.findWithDefault Alive str deadVars of
        Alive -> return ()
        Dead writeToken reason -> do
                    info (getId writeToken) 2030 $ "Modification of " ++ str ++ " is local (to subshell caused by "++ reason ++")."
                    info (getId readToken) 2031 $ str ++ " was modified in a subshell. That change might be lost."
    findSubshelled rest scopes deadVars
  where
    shouldIgnore readToken str =
        str `elem` ["@", "*", "_", "IFS"] || isSyntheticAssignmentRead readToken str

    -- export/declare -x assignments are included in the general variable flow
    -- as references so they count as externally used. That synthetic reference
    -- is not a read of the previous value and must not trigger SC2030/SC2031.
    -- A real RHS read, as in `export foo=$foo`, has a dollar-expansion token and
    -- is deliberately not ignored here.
    isSyntheticAssignmentRead (T_Assignment _ _ name _ _) str = name == str
    isSyntheticAssignmentRead _ _ = False'''

    new_analysis = '''findSubshelled
    (Reference (_, readToken@(T_Assignment _ _ readName _ _), str):
     assignment@(Assignment (base, writeToken, writeName, _)):
     rest)
    scopes
    deadVars
    | isSyntheticCommandReference base readToken writeToken readName str writeName =
        findSubshelled (assignment:rest) scopes deadVars
  where
    isSyntheticCommandReference
        T_SimpleCommand {}
        readToken
        writeToken
        readName
        referencedName
        writtenName =
            getId readToken == getId writeToken &&
            readName == referencedName &&
            referencedName == writtenName
    isSyntheticCommandReference _ _ _ _ _ _ = False

findSubshelled (Reference (_, readToken, str):rest) scopes deadVars = do
    unless (str `elem` ["@", "*", "_", "IFS"]) $ case Map.findWithDefault Alive str deadVars of
        Alive -> return ()
        Dead writeToken reason -> do
                    info (getId writeToken) 2030 $ "Modification of " ++ str ++ " is local (to subshell caused by "++ reason ++")."
                    info (getId readToken) 2031 $ str ++ " was modified in a subshell. That change might be lost."
    findSubshelled rest scopes deadVars'''

    text = replace_exact(text, old_analysis, new_analysis, "analysis block")
    path.write_text(text, encoding="utf-8")
    print("applied command-owned synthetic-reference candidate")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
