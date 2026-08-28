#!/usr/bin/env bash

generate_nbcl() {
  local focused=$(bspc query -D -d focused --names)
  local occupied=$(bspc query -D -d .occupied --names)
  
  local out="box { class=\"workspaces-box\" orientation=\"horizontal\" spacing=6 "
  for i in {1..9}; do
    local state="empty"
    if [[ "$i" == "$focused" ]]; then
      state="active"
    elif echo "$occupied" | grep -q "^$i$"; then
      state="occupied"
    fi
    out+="button { class=\"workspace-btn $state\" onclick=\"bspc desktop -f $i\" label { text=\"$i\" } } "
  done
  out+="}"
  echo "$out"
}

generate_nbcl
bspc subscribe desktop node_transfer node_add node_remove | while read -r _; do
  generate_nbcl
done
