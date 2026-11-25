#!/usr/bin/env bash
# ~/.config/wal/rofi-colors.sh
# Builds rofi's color file from wal's ~/.cache/wal/colors
in="$HOME/.cache/wal/colors"
out="$HOME/.cache/wal/colors-rofi-vars.rasi"
mapfile -t c < <(tr -d ' \r' < "$in")
[ "${#c[@]}" -ge 16 ] || { echo "not enough colors in $in" >&2; exit 1; }
{
  echo "* {"
  echo "    wal-bg: ${c[0]};"
  echo "    wal-fg: ${c[15]};"
  echo "    wal-surface: ${c[8]}44;"
  for i in 0 1 2 3 4 5 6 7 8; do
    echo "    wal-c$i: ${c[$i]};"
  done
  echo "}"
} > "$out"
