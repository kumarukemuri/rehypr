#!/usr/bin/env bash

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "bluetoothctl not found"
    exit 1
fi

bluetoothctl devices | awk '{print $2}' | while read -r mac; do
    if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
        bluetoothctl disconnect "$mac"
    fi
done