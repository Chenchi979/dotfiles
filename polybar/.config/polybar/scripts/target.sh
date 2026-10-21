#!/bin/sh
# Target: lo que escribas con "settarget IP [nombre]"; se borra con "cleartarget"
file="$HOME/.config/bin/target"
target=$( [ -f "$file" ] && head -n1 "$file" )

if [ -n "$target" ]; then
    echo "%{F#f7768e}󰓾%{F-} $target"
else
    echo "%{F#545c7e}󰓾 Sin target%{F-}"
fi
