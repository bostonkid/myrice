#!/usr/bin/env bash
# ~/.config/rofi/wallpaper.sh -- pick a wallpaper in rofi, re-theme everything with pywal
WALL_DIR="${WALL_DIR:-$HOME/Pictures/wallpapers}"

[ -d "$WALL_DIR" ] || { rofi -e "No wallpaper folder at $WALL_DIR"; exit 1; }

choice=$(
    find "$WALL_DIR" -maxdepth 1 -type f \
        \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) \
        -printf '%f\n' | sort |
    while IFS= read -r f; do
        printf '%s\0icon\x1f%s\n' "$f" "$WALL_DIR/$f"
    done |
    rofi -dmenu -i -show-icons -p "󰸉 Wallpaper" -theme-str '
        window   { width: 900px; }
        listview { columns: 4; lines: 3; flow: horizontal; }
        element  { orientation: vertical; padding: 8px; }
        element-icon { size: 160px; horizontal-align: 0.5; }
        element-text { horizontal-align: 0.5; }'
)

[ -n "$choice" ] || exit 0
wal -q -i "$WALL_DIR/$choice" || { rofi -e "wal failed on $choice"; exit 1; }
"$HOME/.config/wal/reload.sh"
