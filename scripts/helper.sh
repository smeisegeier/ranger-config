#!/bin/zsh

# Replaces a specified string with another string in a given file.
# 
# Parameters:
#   file_path (string): The path to the file in which to replace the string.
#   search_string (string): The string to be replaced.
#   replace_string (string): The string to replace the search string with.
# 
# Return:
#   0 if the replacement was successful, 1 if the file was not found.
replace_string_in_file() {
    # Parameters
    local file_path="$1"
    local search_string="$2"
    local replace_string="$3"

    # Check if the file exists
    if [[ ! -f "$file_path" ]]; then
        echo "File not found: $file_path"
        return 1
    fi

    # Check if the search string exists in the file
    if grep -q "$search_string" "$file_path"; then
        echo "Found '$search_string' in $file_path. Replacing it with '$replace_string'..."

        # Determine if running on macOS or Linux
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses `-i ''` for in-place editing without a backup file
            sed -i '' "s|$search_string|$replace_string|g" "$file_path"
        else
            # Linux uses `-i` without additional arguments for in-place editing
            sed -i "s|$search_string|$replace_string|g" "$file_path"
        fi

    else
        echo "'$search_string' not found in $file_path. No changes made."
    fi
}
