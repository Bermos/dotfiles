#!/bin/bash
#    ___
#   / _ \___ _    _____ ____  __ _  ___ ___  __ __
#  / ___/ _ \ |/|/ / -_) __/ /  ' \/ -_) _ \/ // /
# /_/   \___/__,__/\__/_/   /_/_/_/\__/_//_/\_,_/
#
# Compact power menu using wofi dmenu mode

SCRIPTS_DIR="$HOME/.config/hypr/scripts"
WOFI_DIR="$HOME/.config/wofi"

chosen=$(printf "󰌾  Lock\n󰤄  Sleep\n󰍃  Logout\n󰑓  Restart\n󰐥  Shutdown" | wofi --dmenu \
    --conf "$WOFI_DIR/powermenu.conf" \
    --style "$WOFI_DIR/powermenu.css" \
    --cache-file /dev/null)

case "$chosen" in
    *Lock)     "$SCRIPTS_DIR/power.sh" lock ;;
    *Sleep)    "$SCRIPTS_DIR/power.sh" suspend ;;
    *Logout)   "$SCRIPTS_DIR/power.sh" exit ;;
    *Restart)  "$SCRIPTS_DIR/power.sh" reboot ;;
    *Shutdown) "$SCRIPTS_DIR/power.sh" shutdown ;;
esac
