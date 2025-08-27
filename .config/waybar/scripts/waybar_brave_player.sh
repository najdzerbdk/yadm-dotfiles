#!/bin/bash

PLAYER="brave"

# Pobranie tytułu z Brave (YouTube)
title=$(playerctl -p "$PLAYER" metadata title 2>/dev/null)

# Sprawdzenie statusu
status=$(playerctl -p "$PLAYER" status 2>/dev/null)

# Jeśli nic nie gra
if [[ -z "$title" || -z "$status" ]]; then
    echo " Brak filmu"
    exit 0
fi

# Ikona odtwarzania
icon=""
[[ "$status" == "Paused" ]] && icon=""

# Limit 20 znaków
[[ ${#title} -gt 20 ]] && title="${title:0:17}…"

# Ikona nuty
note="♪"

# Wyświetl
echo "  $title $icon "
