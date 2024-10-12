#!/bin/bash

# Requires socat
# Requires swaymsg
# Requires jq
# Requires mpvpaper

# Function to check if a command exists
check_command() {
    command -v "$1" >/dev/null 2>&1 || {
        echo >&2 "Error: Required command '$1' is not installed. Exiting."
        exit 1
    }
}

# Check for required commands
check_command socat
check_command swaymsg
check_command jq
check_command mpvpaper

# Start timer
start_time=$(date +%s%3N)  # Current time in milliseconds

# Base directory for sockets
socket_base="${HOME}/mpvsock-bg-"

# Wallpaper paths
wallpaper_left_path="${HOME}/config/sway/wallpaper/L_SCREEN/"
wallpaper_right_path="${HOME}/config/sway/wallpaper/R_SCREEN/"
mpv_socket_left="${socket_base}left"
mpv_socket_right="${socket_base}right"

# Start mpvpaper instances for left and right monitors
mpvpaper -f -o "input-ipc-server=$mpv_socket_left" -n 10 'DP-2' null &
mpvpaper -f -o "input-ipc-server=$mpv_socket_right" -n 10 'DP-1' null &

# Allow some time for mpvpaper to start
sleep 0.2

# Function to get visible workspace numbers
get_visible_workspaces() {
    swaymsg -t get_workspaces | jq -r '.[] | select(.visible == true) | .num'
}

# Function to set wallpapers based on workspace number
set_wallpaper() {
    case "$1" in
        1) echo "${wallpaper_left_path}wallpaper1.png" ;;
        2) echo "${wallpaper_right_path}wallpaper2.png" ;;
        3) echo "${wallpaper_left_path}wallpaper3.png" ;;
        *) return ;;
    esac
}

# Function to load initial wallpapers for visible workspaces
initial_load_wallpapers() {
    local commands=()
    local workspaces
    workspaces=$(get_visible_workspaces)

    while read -r workspace_num; do
        wallpaper=$(set_wallpaper "$workspace_num")
        if [[ -n $wallpaper ]]; then
            # Determine the appropriate socket based on workspace number
            socket="$mpv_socket_left"
            (( workspace_num % 2 == 0 )) && socket="$mpv_socket_right"
            commands+=("loadfile \"$wallpaper\"")
        fi
    done <<< "$workspaces"

    # Send all commands to socat if there are any
    if [[ ${#commands[@]} -gt 0 ]]; then
        {
            (IFS=$'\n'; echo "${commands[*]}")
        } | socat - "$mpv_socket_left" >/dev/null 2>&1 &
        {
            (IFS=$'\n'; echo "${commands[*]}")
        } | socat - "$mpv_socket_right" >/dev/null 2>&1 &
    fi
}

# Load initial wallpapers
initial_load_wallpapers

# Function to handle workspace changes and update wallpapers
handle_workspace_change() {
    swaymsg -t subscribe -m '[ "workspace" ]' | while read -r event; do
        workspace_num=$(echo "$event" | jq -r '.current.num')
        wallpaper=$(set_wallpaper "$workspace_num")

        if [[ -n $wallpaper ]]; then
            # Determine the appropriate socket based on workspace number
            socket="$mpv_socket_left"
            (( workspace_num % 2 == 0 )) && socket="$mpv_socket_right"

            # Start timing for wallpaper change
            change_start_time=$(date +%s%3N)  # Current time in milliseconds

            # Change the wallpaper in the background
            {
                echo "loadfile \"$wallpaper\""
            } | socat - "$socket" >/dev/null 2>&1 &

            # Calculate and log elapsed time for the change
            change_end_time=$(date +%s%3N)  # Current time in milliseconds
            change_elapsed_time=$(( change_end_time - change_start_time ))  # Calculate elapsed time in ms
            echo "Wallpaper change time for workspace $workspace_num: $change_elapsed_time ms"
        fi
    done
}

# Start listening for workspace changes
handle_workspace_change &

# Silly workaround to trigger initial loading of wallpapers
sleep 0.1; swaymsg workspace 1; sleep 0.1; swaymsg workspace 2; swaymsg workspace 1

# Wait for the background job to finish (it won't, as it's an infinite loop)
wait

# End timer and calculate elapsed time
end_time=$(date +%s%3N)  # Current time in milliseconds
elapsed_time=$(( end_time - start_time ))  # Total execution time in ms

# Print the elapsed time
echo "Total execution time: $elapsed_time ms"
