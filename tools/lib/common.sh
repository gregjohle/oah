#!/bin/bash
# Shared path resolution for OAH tools. Source it; don't run it.
#
#   OAH_ROOT      this repo (derived from this file's location)
#                 default: ${XDG_DATA_HOME:-~/.local/share}/oah/runtime
#   OAH_UPSTREAM_URL  where import tools download the pinned release from
#                 default: https://github.com/basecamp/omarchy.git

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  echo "source tools/lib/common.sh; do not run it directly" >&2
  exit 1
fi

OAH_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd -P)
OAH_PIN=$(tr -d '[:space:]' <"$OAH_ROOT/UPSTREAM")


OAH_UPSTREAM_URL="${OAH_UPSTREAM_URL:-https://github.com/basecamp/omarchy.git}"

export OAH_ROOT OAH_PIN OAH_UPSTREAM_URL

oah_die() {
  printf 'oah: %s\n' "$*" >&2
  exit 1
}

oah_warn() {
  printf 'oah: warning: %s\n' "$*" >&2
}


# Downloads the pinned Omarchy release into DIR (must not exist) and prints
# nothing. Import tools copy from it into OAH, so OAH never depends on a local
# Omarchy checkout.
oah_fetch_upstream() {
  local dir=$1
  [[ ! -e $dir ]] || oah_die "$dir already exists"
  git -c advice.detachedHead=false clone --quiet --depth 1 --branch "$OAH_PIN" -- "$OAH_UPSTREAM_URL" "$dir" ||
    oah_die "could not download Omarchy $OAH_PIN from $OAH_UPSTREAM_URL"
  [[ $(git -C "$dir" describe --tags --exact-match HEAD 2>/dev/null) == "$OAH_PIN" ]] ||
    oah_die "download of $OAH_UPSTREAM_URL isn't at $OAH_PIN"
}
