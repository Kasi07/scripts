#!/bin/zsh

# Function to create links
link_scripts() {
    for script in $1/*.sh; do
        if [[ -x "$script" ]]; then
            sudo ln -sf "$script" "/usr/local/bin/${script:t:r}"
        fi
    done
}

# Check for recursive flag and directory argument
recursive=false
directory="."

for arg in "$@"; do
    if [[ "$arg" == "-r" || "$arg" == "--recursive" ]]; then
        recursive=true
    elif [[ -d "$arg" ]]; then
        directory="$arg"
    fi
done

# Execute the linking process
if $recursive; then
    # Find all .sh files in subdirectories
    for subdir in $(find $directory -type d); do
        link_scripts $subdir
    done
else
    # Link scripts in the specified directory
    link_scripts $directory
fi

