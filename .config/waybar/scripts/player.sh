#!/bin/bash

# --- Lista graczy w kolejności priorytetu ---
PLAYERS=(Lollypop ncmpcpp spotify brave vlc)
CACHE_FILE="/tmp/polybar_selected_player"
ACTIVE_PLAYER=""
FALLBACK_PLAYER=""
VALID_PLAYERS=()

# Zmiana aktywnego gracza przy kliknięciu prawym
if [[ "$1" == "next" ]]; then
    CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
    for player in "${PLAYERS[@]}"; do
        playerctl -p "$player" status &>/dev/null && VALID_PLAYERS+=("$player")
    done
    for ((i=0; i<${#VALID_PLAYERS[@]}; i++)); do
        if [[ "${VALID_PLAYERS[$i]}" == "$CURRENT" ]]; then
            next_index=$(((i + 1) % ${#VALID_PLAYERS[@]}))
            echo "${VALID_PLAYERS[$next_index]}" > "$CACHE_FILE"
            break
        fi
    done
    [[ -z "$CURRENT" && ${#VALID_PLAYERS[@]} -gt 0 ]] && echo "${VALID_PLAYERS[0]}" > "$CACHE_FILE"
    exit 0
fi

# Zatrzymanie wszystkich graczy przy kliknięciu środkowym
if [[ "$1" == "stop" ]]; then
    for player in "${PLAYERS[@]}"; do
        playerctl -p "$player" stop &>/dev/null
    done
    exit 0
fi

# Zmiana głośności w aktywnym graczu
if [[ "$1" == "volup" ]]; then
    playerctl -p "$ACTIVE_PLAYER" volume 2>/dev/null | awk '{print ($1 + 0.05 < 1.0) ? $1 + 0.05 : 1.0}' | xargs -I{} playerctl -p "$ACTIVE_PLAYER" volume {}
    exit 0
elif [[ "$1" == "voldown" ]]; then
    playerctl -p "$ACTIVE_PLAYER" volume 2>/dev/null | awk '{print ($1 - 0.05 > 0.0) ? $1 - 0.05 : 0.0}' | xargs -I{} playerctl -p "$ACTIVE_PLAYER" volume {}
    exit 0
fi

# Odczytaj gracza z pliku cache
SELECTED_PLAYER=$(cat "$CACHE_FILE" 2>/dev/null)

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

# Jeśli ręcznie wybrano gracza i nadal działa oraz coś odtwarza, użyj go
if [[ -n "$SELECTED_PLAYER" ]]; then
    selected_status=$(playerctl -p "$SELECTED_PLAYER" status 2>/dev/null)
    if [[ "$selected_status" == "Playing" || "$selected_status" == "Paused" ]]; then
        ACTIVE_PLAYER="$SELECTED_PLAYER"
    fi
fi

# Jeśli nic nie gra, użyj zapauzowanego
if [[ -z "$ACTIVE_PLAYER" && -n "$FALLBACK_PLAYER" ]]; then
    ACTIVE_PLAYER="$FALLBACK_PLAYER"
fi

# Jeśli nadal nic, zakończ
if [[ -z "$ACTIVE_PLAYER" ]]; then
    echo " Brak odtwarzacza"
    exit 0
fi

# Zapisz wybranego gracza
echo "$ACTIVE_PLAYER" > "$CACHE_FILE"

# Sprawdzanie statusu odtwarzania
status=$(playerctl -p "$ACTIVE_PLAYER" status 2>/dev/null)

# Ikona statusu
if [[ "$status" == "Playing" ]]; then
    icon=""
elif [[ "$status" == "Paused" ]]; then
    icon=""
else
    icon=""
fi

# Kliknięcie – toggle play/pause
if [[ "$1" == "toggle" ]]; then
    if [[ "$status" == "Playing" ]]; then
        playerctl -p "$ACTIVE_PLAYER" pause
    else
        playerctl -p "$ACTIVE_PLAYER" play
    fi
    exit 0
fi

# Pobieranie tytułu
title=$(playerctl -p "$ACTIVE_PLAYER" metadata title 2>/dev/null)
#pobieranie playera
# Zamiast tytułu pobieramy nazwę gracza
title2="$ACTIVE_PLAYER"

# Pobieranie pozycji i długości
position=$(playerctl -p "$ACTIVE_PLAYER" position 2>/dev/null)
length=$(playerctl -p "$ACTIVE_PLAYER" metadata mpris:length 2>/dev/null)

# Obsługa braku danych
if [[ -z "$position" || -z "$length" || "$length" -eq 0 ]]; then
    echo "%{A1:$0 toggle:}%{A2:$0 stop:}%{A3:$0 next:}%{A4:$0 volup:}%{A5:$0 voldown:}$icon ${title:0:60}%{A}%{A}%{A}%{A}%{A}"
    exit 0
fi

# Oblicz postęp (length w mikrosekundach → sekundy)
length_sec=$((length / 1000000))
position_sec=${position%.*}
progress=$((position_sec * 100 / length_sec))

# Formatuj czas
format_time() {
    local t=$1
    printf "%d:%02d" $((t / 60)) $((t % 60))
}

formatted_position=$(format_time "$position_sec")
formatted_length=$(format_time "$length_sec")

# Pasek postępu
bar=""
total_blocks=30
filled=$((progress * total_blocks / 100))
for ((i=0; i<total_blocks; i++)); do
    if (( i == total_blocks / 2 )); then
        bar+="$icon"
    elif (( i < filled )); then
        bar+="─"
    else
        bar+=" "
    fi
done

# Wyświetl pasek z aktualnym czasem, tytułem, maks. czasem i procentem
echo "%{A1:$0 toggle:}%{A2:$0 stop:}%{A3:$0 next:}%{A4:$0 volup:}%{A5:$0 voldown:}$progress% $icon ${title2}%{A}%{A}%{A}%{A}%{A}"
