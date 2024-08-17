#!/bin/zsh

# Determine the OS
os_name=$(uname)
echo "Detected OS: $os_name"

chmod +x scripts/helper.sh
source scripts/helper.sh

# if [[ "$os_name" == "Darwin" ]]; then
#     echo "Found macOS"
# fi

if [[ "$os_name" == "Linux" ]]; then
    replace_string_in_file rc.conf "du -d 3 -h" "du --max-depth=1 -h --apparent-size"
fi

# Function to check if Visual Studio Code (code) is installed
is_code_installed() {
    command -v code > /dev/null 2>&1
}

# Function to check if the Codeium extension is installed in VS Code
is_codium_installed() {
    command -v codium > /dev/null 2>&1
}

# Check both conditions and print results
if ! is_code_installed && ! is_codium_installed; then
    echo "Neither Visual Studio Code (code) nor the Codeium extension is installed."
    echo "Installing Visual Studio Code..."

    # Update package list and install dependencies
    echo "Updating package list..."
    sudo apt update

    echo "Installing dependencies..."
    sudo apt install -y software-properties-common apt-transport-https wget

    echo "Adding VSCodium repository key..."
    sudo wget https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg -O /usr/share/keyrings/vscodium-archive-keyring.asc

    echo "Adding VSCodium repository to sources list..."
    echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.asc ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

    # Update package list again
    echo "Updating package list again..."
    sudo apt update

    # Install Visual Studio Code
    echo "Installing VSCodium..."
    sudo apt install -y codium

else
    echo "At least one of Visual Studio Code (code) or Codium installed."
fi

# Path to the .zshrc file
ZSHRC_PATH="$HOME/.zshrc"

# Check if .zshrc exists
if [ -f "$ZSHRC_PATH" ]; then
    echo "$ZSHRC_PATH exists."
else
    echo "$ZSHRC_PATH does not exist, creating it..."
    touch $ZSHRC_PATH
fi

# Check for alias in .zshrc
if ! is_code_installed && is_codium_installed ; then
    echo "Only codium installed"
    if grep -q "alias code=codium" "$ZSHRC_PATH"; then
        echo "Alias 'code=codium' already present in $ZSHRC_PATH."
    else
        echo "Adding alias 'code=codium' to $ZSHRC_PATH..."
        # echo "alias code=codium" >> "$ZSHRC_PATH"
    fi
else
    echo "No need to add codium alias"
fi

# Define the function to be added to .zshrc
cdd_function='
function cdd {
    local IFS=$'"'\t\n'"'
    local tempfile="$(mktemp -t tmp.XXXXXX)"
    local ranger_cmd=(
        command
        ranger
        --cmd="map q chain shell echo %d > \"$tempfile\"; quitall"
    )
    
    ${ranger_cmd[@]} "$@"
    if [[ -f "$tempfile" ]] && [[ "$(cat -- "$tempfile")" != "$(echo -n $(pwd))" ]]; then
        cd -- "$(cat "$tempfile")" || return
    fi
    command rm -f -- "$tempfile" 2>/dev/null
}
'

# Check for function in .zshrc
if grep -q "function cdd" "$ZSHRC_PATH"; then
    echo "Function 'cdd' already present in $ZSHRC_PATH."
else
    echo "Adding function 'cdd' to $ZSHRC_PATH..."
    echo "$cdd_function" >> "$ZSHRC_PATH"
fi
