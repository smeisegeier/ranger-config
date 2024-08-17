#!/bin/zsh

# Function to find and replace a string in a file
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
        # Perform the replacement using sed
        sed -i '' "s/$search_string/$replace_string/g" "$file_path"
    else
        echo "'$search_string' not found in $file_path. No changes made."
    fi
}
