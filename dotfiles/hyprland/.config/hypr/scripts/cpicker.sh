#!/bin/bash

color=$(hyprpicker -a -f hex) || exit 0

notify-send "Color copied:" "$color"
