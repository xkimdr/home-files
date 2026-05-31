#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

# Get the absolute path to the directory where this script is located
# DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
IGNORE_FILE="$DOTFILES_DIR/ignore.txt"

echo "🚀 Starting dotfiles link process..."
echo "📂 Source directory: $DOTFILES_DIR"
echo "--------------------------------------------------------"

# Build the ignore arguments for grep
# This reads the ignore file, removes comments/empty lines, and prepares patterns
IGNORE_PATTERNS=""
if [ -f "$IGNORE_FILE" ]; then
    # Create a regex pattern: (pattern1|pattern2|pattern3)
    IGNORE_PATTERNS=$(grep -v '^#' "$IGNORE_FILE" | grep -v '^$' | paste -sd "|" - || true)
fi

# Find all files inside 'config' and 'local' using absolute paths
find "$DOTFILES_DIR/config" "$DOTFILES_DIR/local" -type f 2>/dev/null | while read -r absolute_file; do

    # FIX: Strip the absolute DOTFILES_DIR prefix to get the relative path
    repo_file="${absolute_file#"$DOTFILES_DIR"/}"

    # Check if the current file matches any ignore pattern
    if [[ -n "$IGNORE_PATTERNS" && "$repo_file" =~ $IGNORE_PATTERNS ]]; then
        echo "⏭️ Skipping       : .$repo_file"
        continue
    fi

    # Calculate the exact target path in the home directory
    target_file="$HOME/.${repo_file}"
    target_dir="$(dirname "$target_file")"

    # Ensure the parent directory exists in $HOME
    if [ ! -d "$target_dir" ]; then
        mkdir -p "$target_dir"
    fi

    # Check if the file or a broken symlink already exists
    if [ -e "$target_file" ] || [ -L "$target_file" ]; then
        # If it's an existing symlink pointing to our repo, skip it
        if [ "$(readlink "$target_file")" = "$absolute_file" ]; then
            echo "✅ Already linked : .$repo_file"
            continue
        fi

        # Otherwise, remove the existing file/link
        echo "🗑️ Removing old   : .$repo_file"
        rm -f "$target_file"
    fi

    # Create the new symbolic link using the clean absolute path
    echo "🔗 Linking new    : .$repo_file"
    ln -s "$absolute_file" "$target_file"

done

echo "--------------------------------------------------------"
echo "🎉 All dotfiles have been successfully linked!"
