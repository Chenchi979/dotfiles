#!/bin/sh
# ~/.config/rofi/powermenu.sh · menú de apagado (super + shift + e o clic en ⏻ de Polybar)

bloquear="󰌾  Bloquear"
salir="󰍃  Cerrar sesión"
reiniciar="󰜉  Reiniciar"
apagar="⏻  Apagar"

opcion=$(printf '%s\n%s\n%s\n%s\n' "$bloquear" "$salir" "$reiniciar" "$apagar" \
    | rofi -dmenu -i -p "⏻ Sistema" -theme-str 'window {width: 320px;} listview {lines: 4;}')

confirmar() {
    resp=$(printf 'No\nSí\n' | rofi -dmenu -i -p "¿Seguro?" -theme-str 'window {width: 260px;} listview {lines: 2;}')
    [ "$resp" = "Sí" ]
}

case "$opcion" in
    "$bloquear")  i3lock-fancy ;;
    "$salir")     confirmar && bspc quit ;;
    "$reiniciar") confirmar && systemctl reboot ;;
    "$apagar")    confirmar && systemctl poweroff ;;
esac
