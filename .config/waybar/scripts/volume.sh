#!/bin/bash

# Skrypt do obsługi głośności dla Waybar
# Zapisz ten plik jako ~/.config/waybar/scripts/volume.sh
# Upewnij się, że ma uprawnienia do wykonywania: chmod +x ~/.config/waybar/scripts/volume.sh

# Funkcja do uzyskania statusu głośności i formatowania wyjścia JSON
# Ten skrypt nie zwraca JSON, ponieważ moduł 'pulseaudio' Waybar samodzielnie pobiera i formatuje dane.
# Jest odpowiedzialny jedynie za akcje 'up', 'down', 'toggle'.

case "$1" in
    up)
        # Zwiększ głośność o 5%
        pactl set-sink-volume @DEFAULT_SINK@ +5%
        ;;
    down)
        # Zmniejsz głośność o 5%
        pactl set-sink-volume @DEFAULT_SINK@ -5%
        ;;
    toggle)
        # Wycisz/przywróć głośność
        pactl set-sink-mute @DEFAULT_SINK@ toggle
        ;;
    *)
        # Domyślnie nic nie robimy, ponieważ Waybar 'pulseaudio' obsługuje status
        # Jeśli ten skrypt zostałby użyty z 'custom/volume', to ta sekcja by się przydała do zwracania JSON.
        # W tym konkretnym przypadku, Waybar sam odczytuje stan głośności dla modułu pulseaudio.
        ;;
esac
