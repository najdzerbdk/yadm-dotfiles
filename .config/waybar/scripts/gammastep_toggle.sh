#!/bin/bash

# Sprawdza, czy Gammastep jest już uruchomiony.
if pgrep -x "gammastep" > /dev/null
then
    # Jeśli jest, zabija go.
    pkill gammastep
else
    # Jeśli nie, uruchamia Gammastep z domyślnymi opcjami.
    gammastep -O 3500 &
fi