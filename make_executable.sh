#!/bin/zsh

# Function to make scripts executable
make_executable() {
    for file in $1; do
        if [[ -f "$file" && ! -x "$file" ]]; then
            chmod +x "$file"
            echo "Made executable: $file"
        fi
    done
}

# Check if at least one argument is provided
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <file-pattern>"
    exit 1
fi

# Iterate over each argument and make matching files executable
for pattern in "$@"; do
    make_executable "$pattern"
done

