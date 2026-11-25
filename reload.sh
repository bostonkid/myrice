#!/usr/bin/env bash
# ~/.config/wal/reload.sh -- push the current wal colors to the rest of the desktop.
# Run after `wal -i ...` or `wal -r` (wallpaper.sh and the i3 startup line do this).
# Open urxvt windows are already recolored by wal itself.

xrdb -merge "$HOME/.Xresources" 2>/dev/null           # fonts and other urxvt settings
xrdb -merge "$HOME/.cache/wal/colors.xresources"      # wal colors for i3 + polybar
"$HOME/.config/wal/rofi-colors.sh"                    # rofi color file
i3-msg -q reload                                      # re-reads set_from_resource colors
"$HOME/.config/polybar/launch.sh"                     # re-reads ${xrdb:...}
