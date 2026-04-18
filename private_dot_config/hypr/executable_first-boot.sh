#!/usr/bin/env bash
# First-boot setup: install split-monitor-workspaces plugin
# This script runs once when Hyprland is first started

MARKER="$HOME/.config/hypr/.plugin-installed"

if [ -f "$MARKER" ]; then
    exit 0
fi

# Wait for Hyprland to be fully ready
sleep 3

notify-send "Hyprland Setup" "Installing split-monitor-workspaces plugin..." -t 5000

hyprpm update 2>&1
hyprpm add https://github.com/Duckonaut/split-monitor-workspaces 2>&1
hyprpm enable split-monitor-workspaces 2>&1

if hyprpm list 2>&1 | grep -q "split-monitor-workspaces"; then
    touch "$MARKER"
    notify-send "Hyprland Setup" "Plugin installed! Reloading config..." -t 3000
    hyprctl reload
else
    notify-send "Hyprland Setup" "Plugin install failed. Run manually:\nhyprpm update && hyprpm add https://github.com/Duckonaut/split-monitor-workspaces && hyprpm enable split-monitor-workspaces" -t 10000
fi
