#!/bin/bash
cliphist list | rofi -dmenu --width 600 --height 400 | cliphist decode | wl-copy
