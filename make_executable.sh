#!/bin/bash

# make_executable - make files executable according to pattern
# Usage: make_executable [OPTIONS] [PATTERN...]

# Default settings
verbose=0
dry_run=0
recursive=0
exit_status=0
color_output=1

# Check if colors should be disabled
if [[ -n "${NO_COLOR}" || "${TERM}" == "dumb" ]]; then
  color_output=0
fi

# Color definitions
if [[ $color_output -eq 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  NC=""
fi

# Function to show usage
usage() {
    cat >&2 <<EOF
Usage: $(basename "$0") [OPTIONS] [PATTERN...]
Make files executable that match the specified pattern(s).

Options:
  -h, --help     display this help and exit
  -v, --verbose  explain what is being done
  -n, --dry-run  show what would be done without making changes
  -r, --recursive search directories recursively
EOF
}

# Function for error messages
error_msg() {
    printf "${RED}error:${NC} %s\n" "$1" >&2
}

# Function to show help hint
help_hint() {
    printf "Try '${BLUE}%s --help${NC}' for more information.\n" "$(basename "$0")" >&2
}

# Function to make a single file executable if it's not already
make_file_executable() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return 1
    fi
    
    if [[ -x "$file" ]]; then
        [[ "$verbose" -eq 1 ]] && printf "${YELLOW}already executable${NC} '%s'\n" "$file"
        return 1
    fi
    
    if [[ "$dry_run" -eq 1 ]]; then
        printf "${BLUE}would make executable${NC} '%s'\n" "$file"
        return 0
    else
        chmod +x "$file" || { error_msg "failed to make executable '$file'"; return 1; }
        [[ "$verbose" -eq 1 ]] && printf "${GREEN}made executable${NC} '%s'\n" "$file"
        return 0
    fi
}

# Function to normalize paths
normalize_path() {
    local path="$1"
    # Remove unnecessary ./ prefixes, double slashes, etc.
    echo "$(cd "$(dirname "$path")" 2>/dev/null && pwd -P)/$(basename "$path")" 2>/dev/null || echo "$path"
}

# Function to process patterns
process_pattern() {
    local pattern="$1"
    local file_count_local=0
    
    if [[ -f "$pattern" ]]; then
        # It's a file
        if make_file_executable "$pattern"; then
            ((file_count_local++))
        fi
    else
        # It's a pattern
        [[ "$verbose" -eq 1 ]] && printf "${BLUE}searching for${NC} %s\n" "$pattern"
        
        local directory
        local filename_pattern
        
        if [[ "$pattern" == */* ]]; then
            directory=$(dirname "$pattern")
            filename_pattern=$(basename "$pattern")
        else
            directory=.
            filename_pattern="$pattern"
        fi
        
        # Build find command based on recursive flag
        local find_cmd=("-type" "f" "-name" "$filename_pattern")
        
        if [[ "$recursive" -eq 0 ]]; then
            find_cmd+=("-maxdepth" "1")
        fi
        
        # Use find to locate matching files
        while IFS= read -r -d '' file; do
            if make_file_executable "$file"; then
                ((file_count_local++))
            fi
        done < <(find "$directory" "${find_cmd[@]}" -print0 2>/dev/null)
    fi
    
    return $file_count_local
}

# Parse options using getopts
while getopts ":hvnr-:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        v)
            verbose=1
            ;;
        n)
            dry_run=1
            verbose=1  # Dry run implies verbose
            ;;
        r)
            recursive=1
            ;;
        -)
            case "${OPTARG}" in
                help)
                    usage
                    exit 0
                    ;;
                verbose)
                    verbose=1
                    ;;
                dry-run)
                    dry_run=1
                    verbose=1  # Dry run implies verbose
                    ;;
                recursive)
                    recursive=1
                    ;;
                *)
                    error_msg "unknown option --${OPTARG}"
                    help_hint
                    exit 1
                    ;;
            esac
            ;;
        \?)
            error_msg "unknown option -${OPTARG}"
            help_hint
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))
patterns=("$@")

# Process files
file_count=0

# No patterns provided - show error and exit
if [[ ${#patterns[@]} -eq 0 ]]; then
    error_msg "missing file operand"
    help_hint
    exit 1
else
    # Process each pattern
    for pattern in "${patterns[@]}"; do
        count=0
        process_pattern "$pattern"
        count=$?
        file_count=$((file_count + count))
    done
fi

# Output summary (only in verbose mode)
if [[ "$verbose" -eq 1 ]]; then
    if [[ "$dry_run" -eq 1 ]]; then
        printf "${BLUE}Summary:${NC} "
    else
        printf "${GREEN}Summary:${NC} "
    fi
    
    if [[ "$file_count" -eq 0 ]]; then
        printf "no files were made executable\n"
    elif [[ "$file_count" -eq 1 ]]; then
        printf "1 file made executable\n"
    else
        printf "%d files made executable\n" "$file_count"
    fi
fi

# Return proper exit code: 0 if files were made executable, 1 otherwise
[[ "$file_count" -gt 0 ]] && exit 0 || exit 1
