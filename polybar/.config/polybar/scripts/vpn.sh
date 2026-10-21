#!/bin/sh
# VPN: muestra la IP de tun0 (HTB, TryHackMe, OpenVPN) o "VPN off"
#   vpn.sh        → lo que muestra Polybar
#   vpn.sh copy   → copia la IP de la VPN al portapapeles (clic en el módulo)
ip=$(ip -4 -o addr show dev tun0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)

if [ "$1" = "copy" ]; then
    [ -n "$ip" ] && printf '%s' "$ip" | xclip -selection clipboard \
        && notify-send -t 1500 "IP de la VPN copiada" "$ip" 2>/dev/null
    exit 0
fi

if [ -n "$ip" ]; then
    echo "%{F#9ece6a}󰆧%{F-} $ip"
else
    echo "%{F#545c7e}󰆧 VPN off%{F-}"
fi
