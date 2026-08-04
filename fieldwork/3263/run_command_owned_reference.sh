#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: run_command_owned_reference.sh SHELLCHECK_ROOT" >&2
  exit 2
fi

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$1" && pwd)
cd "$root"

test "$(git rev-parse HEAD)" = a1716be3b847dc23761d35137b43cef7752b3c1d
python3 "$script_dir/apply_command_owned_reference.py" "$root"
git diff --check

cabal v2-test test-shellcheck --test-show-details=direct
cabal v2-build exe:shellcheck
bin=$(cabal list-bin exe:shellcheck)

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

cat > "$tmp/literal.bats" <<'EOF'
#!/usr/bin/env bats
@test "one" { export foo=bar; }
@test "two" { export foo=baz; }
EOF
! "$bin" -f gcc "$tmp/literal.bats" | grep -Eq 'SC2030|SC2031'

cat > "$tmp/append.bats" <<'EOF'
#!/usr/bin/env bats
@test "one" { foo=bar; }
@test "two" { export foo+=baz; }
EOF
set +e
"$bin" -f gcc "$tmp/append.bats" > "$tmp/append.txt"
append_status=$?
set -e
test "$append_status" -ne 0
grep -q 'SC2030' "$tmp/append.txt"
grep -q 'SC2031' "$tmp/append.txt"

cat > "$tmp/bare-export.bats" <<'EOF'
#!/usr/bin/env bats
@test "one" { foo=bar; }
@test "two" { export foo; }
EOF
set +e
"$bin" -f gcc "$tmp/bare-export.bats" > "$tmp/bare-export.txt"
bare_status=$?
set -e
test "$bare_status" -ne 0
grep -q 'SC2030' "$tmp/bare-export.txt"
grep -q 'SC2031' "$tmp/bare-export.txt"

test "$(git rev-parse HEAD)" = a1716be3b847dc23761d35137b43cef7752b3c1d
git diff --check
test "$(git diff --name-only)" = src/ShellCheck/Analytics.hs

echo "ShellCheck command-owned reference controls passed"
