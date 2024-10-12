# ws-swaybg-mpvpaper
A bash script using mpvpaper for sway to change background wallpaper per workspace

# Wallpaper Manager for Sway

This Bash script manages wallpapers for multiple monitors using `mpvpaper` and `sway`. It dynamically updates wallpapers based on the current visible workspace in a Sway tiling window manager environment. The script utilizes IPC (Inter-Process Communication) to send commands to `mpvpaper`, which handles wallpaper display.

## Features

- **Dynamic Wallpaper Management**: Automatically changes wallpapers based on the active workspace.
- **Multi-Monitor Support**: Configured to handle multiple monitors.
- **Performance Tracking**: Logs the time taken to change wallpapers.
- **Silently Operates**: Redirects unnecessary output to `/dev/null` for a cleaner user experience.

## Requirements

Before running the script, ensure you have the following dependencies installed:

- `socat`
- `swaymsg`
- `jq`
- `mpvpaper`

### Installation

1. TODO

### Usage

You absolutely need to give it wallpapers the exact size of your resolution, otherwise the wallpaper won't be filling your deskltop