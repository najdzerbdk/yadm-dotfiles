#!/bin/bash

# sprawdzamy aktualny stan
CURRENT=$(pactl list sinks | grep -m1 "channel map" | awk '{print $3}')

if [[ "$CURRENT" == "front-left,front-right" ]]; then
    # stereo -> mono
    pactl set-sink-channel-map @DEFAULT_SINK@ mono
    notify-send "🎧 Audio" "Przełączono na MONO"
else
    # mono -> stereo
    pactl set-sink-channel-map @DEFAULT_SINK@ front-left,front-right
    notify-send "🎧 Audio" "Przełączono na STEREO"
fi
