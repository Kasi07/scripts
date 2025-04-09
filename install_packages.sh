#!/bin/bash

# Function to detect the Linux distribution and return the package manager
detect_package_manager() {
    # Check for Debian/Ubuntu (apt)
    if command -v apt-get &> /dev/null; then
        echo "apt-get"
    # Check for Fedora (dnf)
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    # Check for Arch Linux (pacman)
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    # Check for Opensuse (zypper)
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    # Add more package managers/distributions if needed
    else
        echo "Unknown"
    fi
}

# Main installation function
install_packages() {
    pkg_manager=$(detect_package_manager)

    if [ "$pkg_manager" = "Unknown" ]; then
        echo "Package manager could not be detected. Exiting."
        exit 1
    fi

    for pkg in "$@"; do
        echo "Installing $pkg..."
        if [ "$pkg_manager" = "apt-get" ]; then
            sudo apt-get install -y $pkg
        elif [ "$pkg_manager" = "dnf" ]; then
            sudo dnf install -y $pkg
        elif [ "$pkg_manager" = "pacman" ]; then
            sudo pacman -S --noconfirm $pkg
        fi
    done
}

# Check if any arguments are provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 package1 [package2 ...]"
    exit 1
fi

# Install packages
install_packages "$@"

