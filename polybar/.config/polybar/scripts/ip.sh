#!/bin/sh
# Tu IP local: la de la interfaz que sale a internet (eth0, ens33, wlan0…)
#   ip.sh        → lo que muestra Polybar
#   ip.sh copy   → copia la IP al portapapeles (clic en el módulo)
iface=$(ip route show default 2>/dev/null | awk '/default/ {print $5; exit}')
ip=$(ip -4 -o addr show dev "$iface" 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)

if [ "$1" = "copy" ]; then
    [ -n "$ip" ] && printf '%s' "$ip" | xclip -selection clipboard \
        && notify-send -t 1500 "IP copiada" "$ip" 2>/dev/null
    exit 0
fi

if [ -n "$ip" ]; then
    echo "%{F#7aa2f7}󰩟%{F-} $ip"
else
    echo "%{F#f7768e}󰩟%{F-} sin red"
fi
