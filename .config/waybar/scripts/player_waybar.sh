#!/bin/bash

PLAYERS=(ncmpcpp spotify vlc)
CACHE_FILE="/tmp/waybar_selected_player"
ACTIVE_PLAYER=""
FALLBACK_PLAYER=""
VALID_PLAYERS=()

# Obsługa argumentów (kliknięcia)
case "$1" in
    toggle)
        SELECTED_PLAYER=$(cat "$CACHE_FILE" 2>/dev/null)
        [[ -n "$SELECTED_PLAYER" ]] && playerctl -p "$SELECTED_PLAYER" play-pause
        exit 0
        ;;
    stop)
        for p in "${PLAYERS[@]}"; do playerctl -p "$p" stop &>/dev/null; done
        exit 0
        ;;
    next)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        for player in "${PLAYERS[@]}"; do
            playerctl -p "$player" status &>/dev/null && VALID_PLAYERS+=("$player")
        done
        for ((i=0;i<${#VALID_PLAYERS[@]};i++)); do
            if [[ "${VALID_PLAYERS[$i]}" == "$CURRENT" ]]; then
                NEXT="${VALID_PLAYERS[$(( (i+1) % ${#VALID_PLAYERS[@]} ))]}"
                echo "$NEXT" > "$CACHE_FILE"
                exit 0
            fi
        done
        [[ ${#VALID_PLAYERS[@]} -gt 0 ]] && echo "${VALID_PLAYERS[0]}" > "$CACHE_FILE"
        exit 0
        ;;
esac

# Szukanie aktywnego gracza
for player in "${PLAYERS[@]}"; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    [[ "$status" == "Playing" || "$status" == "Paused" ]] && VALID_PLAYERS+=("$player")
    if [[ "$status" == "Playing" ]]; then
        ACTIVE_PLAYER="$player"
        break
    elif [[ "$status" == "Paused" && -z "$FALLBACK_PLAYER" ]]; then
        FALLBACK_PLAYER="$player"
    fi
done

SELECTED_PLAYER=$(cat "$CACHE_FILE" 2>/dev/null)
[[ -n "$SELECTED_PLAYER" && " ${VALID_PLAYERS[*]} " =~ " $SELECTED_PLAYER " ]] && ACTIVE_PLAYER="$SELECTED_PLAYER"
[[ -z "$ACTIVE_PLAYER" && -n "$FALLBACK_PLAYER" ]] && ACTIVE_PLAYER="$FALLBACK_PLAYER"

[[ -z "$ACTIVE_PLAYER" ]] && { echo "  Brak odtwarzacza"; exit 0; }

echo "$ACTIVE_PLAYER" > "$CACHE_FILE"
status=$(playerctl -p "$ACTIVE_PLAYER" status 2>/dev/null)
icon=""
[[ "$status" == "Paused" ]] && icon=""

# Pobranie tytułu i artysty
title=$(playerctl -p "$ACTIVE_PLAYER" metadata title 2>/dev/null)
artist=$(playerctl -p "$ACTIVE_PLAYER" metadata artist 2>/dev/null)

# Obsługa braku danych
[[ -z "$title" ]] && title="Nieznany utwór"
[[ -z "$artist" ]] && artist="Nieznany artysta"

# Ikona nuty
note="♪"

# Wyświetl w Waybar
echo " $icon  $artist – $title"
