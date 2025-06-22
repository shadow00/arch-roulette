#!/bin/bash
# Copyright (C) 2025 shadow00
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# Constants
REPO_FILE="/etc/pacman.conf"
PACKAGE_CACHE_FILE="/tmp/arch_roulette_packages.txt"
LOG_DIR="/var/log/arch-roulette"
LOG_FILE="${LOG_DIR}/$(date '+%Y-%m-%d_%H-%M-%S').log"

# Set default package manager
PACKAGE_MANAGER="pacman"

# Function to display help message
show_help() {
    echo "Arch Roulette - A package management game for Arch Linux"
    echo ""
    echo "Description:"
    echo "  Randomly installs or removes packages from your system, creating an exciting"
    echo "  game of system modification. Use with caution!"
    echo ""
    echo "Usage: arch-roulette [options]"
    echo "       arch-roulette play [options]  # To play the game"
    echo ""
    echo "Options:"
    echo "  -h, --help      Show this help message and exit"
    echo "  -n, --dry-run   Show what would happen without making changes"
    echo "  -s, --safe-mode  Ask for confirmation before making changes"
    echo "  -H, --hardcore  Use paru (includes AUR packages)"
    echo ""
    echo "Example:"
    echo "  arch-roulette                    # Show help"
    echo "  arch-roulette play --dry-run     # See what would happen"
    echo "  arch-roulette play --safe-mode   # Ask before changes"
    echo "  arch-roulette play --hardcore    # Include AUR packages"
}

# Show the help message if no arguments are passed
if [ $# -eq 0 ]; then
    show_help
    exit 0
fi

# Function to initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    find "$LOG_DIR" -type f -name "*.log" -mtime +30 -delete
    echo "$(date '+%Y-%m-%d %H:%M:%S') - Arch Roulette initialized" >> "$LOG_FILE"
}

# Function to log actions
log_action() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Helper function to check if package is installed
is_package_installed() {
    $PACKAGE_MANAGER -Qi "$1" >/dev/null 2>&1
}

# Helper function to get available packages
get_available_packages() {
    $PACKAGE_MANAGER -Slq --noconfirm > "$PACKAGE_CACHE_FILE"
    awk '!/^@/' "$PACKAGE_CACHE_FILE"
}

# Helper function to install package
install_package() {
    local package="$1"
    log_action "Attempting to install package '$package'"
    echo "Installing package: $package"
    sudo $PACKAGE_MANAGER -S --noconfirm "$package"
    log_action "Installation completed for '$package'"
}

# Helper function to remove package
remove_package() {
    local package="$1"
    log_action "Attempting to remove package '$package'"
    echo "Removing package: $package"
    sudo $PACKAGE_MANAGER -Rs --noconfirm "$package"
    log_action "Removal completed for '$package'"
}

# Are we playing?
PLAY_MODE="false"

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        play)
            PLAY_MODE="true"
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        --dry-run|-n)
            DRY_RUN="true"
            shift
            ;;
        --safe-mode|-s)
            SAFE_MODE="true"
            shift
            ;;
        --hardcore|-H)
            PACKAGE_MANAGER="paru"
            shift
            ;;
        *)
            echo "Error: Unknown option '$1'"
            echo "Try 'arch-roulette --help' for usage information"
            exit 1
            ;;
    esac
done

# Stop if we're not playing
if [ "$PLAY_MODE" = "false" ]; then
    echo "Error: The 'play' flag is required to run the game"
    echo "Usage: arch-roulette play [options]"
    exit 1
fi

# Main program flow
if ! command -v $PACKAGE_MANAGER &>/dev/null; then
    echo "Error: $PACKAGE_MANAGER package manager not found!"
    exit 1
fi

# Main game logic
init_logging

action=$(($RANDOM % 2))

if [ $action -eq 0 ]; then
    # Install mode
    available_packages=$(get_available_packages)
    if [ -z "$available_packages" ]; then
        log_action "ERROR: Could not retrieve package list!"
        echo "Error: Could not retrieve package list!"
        exit 1
    fi

    selected_package=$(echo "$available_packages" | shuf -n 1)

    if [ "$DRY_RUN" = "true" ]; then
        log_action "Dry-run: Would install package '$selected_package'"
        echo "Would install: $selected_package"
    elif [ "$SAFE_MODE" = "false" ] || [ "$(confirm_action 'Install')" = "yes" ]; then
        install_package "$selected_package"
    fi

else
    # Uninstall mode
    installed_packages=$(pacman -Qq)
    if [ -z "$installed_packages" ]; then
        log_action "ERROR: No packages found!"
        echo "Error: No packages found!"
        exit 1
    fi

    available_for_removal=()
    while IFS= read -r pkg; do
        available_for_removal+=("$pkg")
    done <<< "$installed_packages"

    if [ ${#available_for_removal[@]} -eq 0 ]; then
        log_action "ERROR: No removable packages found!"
        echo "Error: No removable packages found!"
        exit 1
    fi

    selected_package=${available_for_removal[$RANDOM % ${#available_for_removal[@]} ]}

    if [ "$DRY_RUN" = "true" ]; then
        log_action "Dry-run: Would remove package '$selected_package'"
        echo "Would remove: $selected_package"
    elif [ "$SAFE_MODE" = "false" ] || [ "$(confirm_action 'Remove')" = "yes" ]; then
        remove_package "$selected_package"
    fi
fi

log_action "Game session ended"