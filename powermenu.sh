#!/usr/bin/env bash
# ~/.config/rofi/powermenu.sh
lock() { i3lock -n -c "$(xrdb -query | awk '/^\*\.?background:/{print substr($2,2); exit}')"; }

choice=$(printf '%s\n' "  Lock" "󰍃  Logout" "󰤄  Suspend" "  Reboot" "  Shutdown" \
    | rofi -dmenu -i -p "Power" -theme-str 'window {width: 300px;} listview {lines: 5;}')

confirm() {
    [ "$(printf 'No\nYes\n' | rofi -dmenu -i -p "$1?" \
        -theme-str 'window {width: 260px;} listview {lines: 2;}')" = "Yes" ]
}

case "$choice" in
    *Lock)     lock & ;;
    *Logout)   confirm "Logout"   && i3-msg exit ;;
    *Suspend)  { lock & } ; sleep 0.5; systemctl suspend ;;
    *Reboot)   confirm "Reboot"   && systemctl reboot ;;
    *Shutdown) confirm "Shutdown" && systemctl poweroff ;;
esac
