#!/bin/bash
# Shared path resolution for OAH tools. Source it; don't run it.
#
#   OAH_ROOT      this repo (derived from this file's location)
#   OAH_UPSTREAM  Omarchy checkout at the pinned release
#                 default: $OAH_ROOT/../omarchy (development layout), else
#                 ${XDG_DATA_HOME:-~/.local/share}/oah/omarchy (installed layout)
#   OAH_RUNTIME   assembled OMARCHY_PATH tree (upstream + OAH overrides)
#                 default: ${XDG_DATA_HOME:-~/.local/share}/oah/runtime

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  echo "source tools/lib/common.sh; do not run it directly" >&2
  exit 1
fi

OAH_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
OAH_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/oah"
OAH_PIN=$(tr -d '[:space:]' <"$OAH_ROOT/UPSTREAM")

if [[ -z ${OAH_UPSTREAM:-} ]]; then
  if [[ -d $OAH_ROOT/../omarchy/.git ]]; then
    OAH_UPSTREAM=$(cd -- "$OAH_ROOT/../omarchy" && pwd -P)
  else
    OAH_UPSTREAM="$OAH_DATA_HOME/omarchy"
  fi
fi

OAH_RUNTIME="${OAH_RUNTIME:-$OAH_DATA_HOME/runtime}"

export OAH_ROOT OAH_UPSTREAM OAH_RUNTIME OAH_PIN

oah_die() {
  printf 'oah: %s\n' "$*" >&2
  exit 1
}

oah_warn() {
  printf 'oah: warning: %s\n' "$*" >&2
}

# Fails unless the upstream checkout exists and is at the pinned release tag.
# OAH_ALLOW_UNPINNED=1 downgrades a mismatch to a warning (for upgrade work).
oah_require_upstream() {
  [[ -f $OAH_UPSTREAM/shell/shell.qml ]] ||
    oah_die "no Omarchy checkout at $OAH_UPSTREAM (set OAH_UPSTREAM, or clone basecamp/omarchy at $OAH_PIN there)"

  local at
  at=$(git -C "$OAH_UPSTREAM" describe --tags --exact-match HEAD 2>/dev/null || true)
  if [[ $at != "$OAH_PIN" ]]; then
    if [[ ${OAH_ALLOW_UNPINNED:-0} == 1 ]]; then
      oah_warn "upstream is at '${at:-untagged}', not the pinned $OAH_PIN"
    else
      oah_die "upstream at $OAH_UPSTREAM is at '${at:-untagged}', expected pinned release $OAH_PIN (run: git -C \"$OAH_UPSTREAM\" checkout $OAH_PIN)"
    fi
  fi
}
