#!/bin/bash
# tools/oah-runtime: tree layout, bin overrides, pin enforcement, safety.
# Runs against a small fake upstream so it's fast and needs no real checkout.

set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../lib" && pwd)/base.sh"

scratch="" && new_scratch scratch

# A fake upstream: a git repo tagged with the pin, with the entries oah-runtime
# cares about.
upstream=$scratch/omarchy
mkdir -p "$upstream"/{shell,bin,config,themes}
echo 'import QtQuick' >"$upstream/shell/shell.qml"
printf '#!/bin/sh\necho upstream-a\n' >"$upstream/bin/omarchy-a"
printf '#!/bin/sh\necho upstream-b\n' >"$upstream/bin/omarchy-b"
chmod +x "$upstream"/bin/*
echo 4.5 >"$upstream/version"
git -C "$upstream" init -q
git -C "$upstream" -c user.name=t -c user.email=t@t add -A
git -C "$upstream" -c user.name=t -c user.email=t@t commit -qm init
git -C "$upstream" tag v-test

# A copy of the OAH tools with its own bin/ overrides, so the test never
# depends on what the real repo overrides.
oah=$scratch/oah
mkdir -p "$oah/bin"
cp -r "$OAH_ROOT/tools" "$oah/"
echo v-test >"$oah/UPSTREAM"
printf '#!/bin/sh\necho oah-b\n' >"$oah/bin/omarchy-b"
printf '#!/bin/sh\necho oah-new\n' >"$oah/bin/omarchy-new"
chmod +x "$oah"/bin/*

runtime=$scratch/runtime
run_tool() { OAH_UPSTREAM=$upstream OAH_RUNTIME=$runtime "$oah/tools/oah-runtime" "$@"; }

out=$(cd / && run_tool) || fail "builds from any working directory" "$out"
pass "builds from any working directory"

[[ -f $runtime/.oah-pin && $(cat "$runtime/.oah-pin") == v-test ]] || fail "records the pin in .oah-pin"
pass "records the pin in .oah-pin"

[[ $(readlink "$runtime/config") == "$upstream/config" && $(readlink "$runtime/version") == "$upstream/version" ]] ||
  fail "symlinks upstream entries"
pass "symlinks upstream entries"

[[ ! -e $runtime/.git ]] || fail "leaves out upstream .git"
pass "leaves out upstream .git"

[[ $(readlink "$runtime/shell") == "$upstream/shell" ]] || fail "uses upstream shell when OAH has none"
pass "uses upstream shell when OAH has none"

[[ -d $runtime/bin && ! -L $runtime/bin ]] || fail "bin is a real directory"
[[ $("$runtime/bin/omarchy-a") == upstream-a ]] || fail "keeps upstream commands"
[[ $("$runtime/bin/omarchy-b") == oah-b ]] || fail "OAH bin overrides a same-named upstream command"
[[ $("$runtime/bin/omarchy-new") == oah-new ]] || fail "OAH bin adds new commands"
pass "bin: upstream commands, OAH overrides and additions"

mkdir -p "$oah/shell"
run_tool >/dev/null
[[ $(readlink "$runtime/shell") == "$oah/shell" ]] || fail "uses OAH's shell once it exists"
pass "uses OAH's shell once it exists"

rm "$oah/bin/omarchy-b"
run_tool >/dev/null
[[ $("$runtime/bin/omarchy-b") == upstream-b ]] || fail "rebuild drops a removed override"
pass "rebuild drops a removed override"

[[ $(run_tool --print) == "$runtime" ]] || fail "--print prints the runtime path"
pass "--print prints the runtime path"

foreign=$scratch/foreign
mkdir -p "$foreign" && touch "$foreign/keep"
if OAH_UPSTREAM=$upstream OAH_RUNTIME=$foreign "$oah/tools/oah-runtime" >/dev/null 2>&1; then
  fail "refuses to replace a directory it didn't build"
fi
[[ -f $foreign/keep ]] || fail "leaves a foreign directory untouched"
pass "refuses to replace a directory it didn't build, and leaves it untouched"

git -C "$upstream" -c user.name=t -c user.email=t@t commit -q --allow-empty -m later
if run_tool >/dev/null 2>&1; then
  fail "refuses an upstream that isn't at the pinned tag"
fi
pass "refuses an upstream that isn't at the pinned tag"

out=$(OAH_ALLOW_UNPINNED=1 run_tool 2>&1 >/dev/null) || fail "OAH_ALLOW_UNPINNED=1 builds anyway"
[[ $out == *"not the pinned v-test"* ]] || fail "OAH_ALLOW_UNPINNED=1 warns" "$out"
pass "OAH_ALLOW_UNPINNED=1 warns and builds"

if OAH_UPSTREAM=$scratch/nonexistent OAH_RUNTIME=$runtime "$oah/tools/oah-runtime" >/dev/null 2>&1; then
  fail "fails clearly without an upstream checkout"
fi
pass "fails clearly without an upstream checkout"
