Note: Written by Claude Code

# dotfiles

My personal configs for Arch Linux + Hyprland, managed with [chezmoi](https://www.chezmoi.io/).

## What's in here

- **Hyprland** — `hyprland.conf`, `hypridle.conf`, `hyprlock.conf`, `hyprpaper.conf`
- **Quickshell** — bar, panels, OSD
- **Terminal** — Ghostty
- **Shell** — bash
- **Notifications** — mako
- **Scratchpads** — pyprland (spotify)
- **Alt+Tab** — hyprswitch styling
- **Media** — mpv with ModernZ OSC
- **Gaming** — gamemode tuning
- **Qt theming** — qt6ct + Kvantum (MacTahoe Dark)
- **Fonts** — fontconfig
- **Scripts** — `~/.local/bin/video-center`

## Apply on a new machine

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply garpu-ng
```

## Update the repo from current system

```bash
chezmoi re-add            # pull current file state back into source
chezmoi cd                # drop into ~/.local/share/chezmoi
git add -A && git commit -m "update" && git push
exit                      # leave the chezmoi subshell
```

## Sync repo changes back to the system

```bash
chezmoi update            # git pull + apply
```

## System context

- Arch Linux (linux-zen), Hyprland compositor
- NVIDIA RTX 5080, dual monitors (DP-1 3440x1440, DP-2 1920x1080)
- Tiling: hy3
- Display manager: ly
- Secure Boot: sbctl
