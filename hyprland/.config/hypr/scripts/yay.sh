#!/bin/bash

set -e

echo ">>> Installing base dependencies..."
sudo pacman -S --needed --noconfirm git base-devel

# Install yay if not present
if ! command -v yay &> /dev/null; then
  echo ">>> yay not found, installing..."
  cd /tmp
  git clone https://aur.archlinux.org/yay.git
  cd yay
  makepkg -si --noconfirm
  cd ..
  rm -rf yay
else
  echo ">>> yay is already installed."
fi