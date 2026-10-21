#!/bin/sh
# ~/.config/polybar/launch.sh · cierra las barras anteriores y lanza la nueva

polybar-msg cmd quit >/dev/null 2>&1
killall -q polybar
while pgrep -u "$(id -u)" -x polybar >/dev/null; do sleep 0.2; done

polybar main 2>&1 | tee -a /tmp/polybar-"$(id -un)".log >/dev/null &
