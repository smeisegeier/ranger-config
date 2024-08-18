#!/bin/zsh

# Color codes
green='\033[0;32m'
yellow='\033[1;33m'
headline_color='\033[1;36m'  # cyan for headlines
bold='\033[1m'
reset='\033[0m'  # reset color

# Ask the user if they want to install oh-my-posh
echo -n "Do you want to install oh-my-posh? (y/[n]): "
read response

# Convert response to lowercase
response=$(echo "$response" | tr '[:upper:]' '[:lower:]')

if [[ "$response" == "y" || "$response" == "yes" ]]; then
    if [ -x "./scripts/install-posh.sh" ]; then
        ./scripts/install-posh.sh
    else
        echo "${yellow} | -- install-posh.sh not found or not executable.${reset}"
    fi
else
    echo "${green} | -- skipping oh-my-posh installation.${reset}"
fi

# Determine the OS
os_name=$(uname)

# Set commands based on OS
case "$os_name" in
    Darwin)
        echo "${bold}${headline_color}Found macOS. Using Homebrew (brew) for package installation.${reset}"
        update_cmd="brew update"
        install_cmd="brew install"
        install_cmd_cask="brew install --cask"
        ;;
    Linux)
        # Check if Fedora or another Linux distro
        if command -v dnf > /dev/null 2>&1; then
            echo "${bold}${headline_color}Found Fedora. Using DNF for package installation.${reset}"
            update_cmd="sudo dnf update -y"
            install_cmd="sudo dnf install -y"
        elif command -v apt > /dev/null 2>&1; then
            echo "${bold}${headline_color}Found Ubuntu. Using APT for package installation.${reset}"
            update_cmd="sudo apt update"
            install_cmd="sudo apt install -y"
        else
            echo "${yellow} | -- Unsupported Linux distribution.${reset}"
            exit 1
        fi
        ;;
    *)
        echo "${yellow} | -- Unsupported OS: $os_name.${reset}"
        exit 1
        ;;
esac

chmod +x scripts/helper.sh
source scripts/helper.sh

eval "$install_cmd ranger fzf atool highlight w3m"

# Linux-specific tasks: replace ranger commands with Linux-specific ones
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

echo "${bold}${headline_color}Checking if Visual Studio Code (code) or Codium is installed...${reset}"

# Check both conditions and print results
if ! is_code_installed && ! is_codium_installed; then
    echo "${yellow} | -- Neither Visual Studio Code (code) nor the Codeium extension is installed.${reset}"
    echo " | -- Installing Visual Studio Code..."

    # Update package list and install dependencies
    echo " | -- Updating package list..."
    eval "$update_cmd"

    echo " | -- Installing dependencies..."
    eval "$install_cmd software-properties-common apt-transport-https wget"

    # Install VSCodium
    if [[ "$os_name" == "Darwin" ]]; then
        echo " | -- Installing VSCodium using Homebrew..."
        eval "$install_cmd_cask vscodium"
    elif [[ "$os_name" == "Linux" && $(command -v dnf) ]]; then
        echo " | -- Installing VSCodium using DNF..."
        eval "$install_cmd vscodium"
    else
        echo " | -- Adding VSCodium repository key..."
        sudo wget https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg -O /usr/share/keyrings/vscodium-archive-keyring.asc

        echo " | -- Adding VSCodium repository to sources list..."
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.asc ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

        # Update package list again
        echo " | -- Updating package list again..."
        eval "$update_cmd"

        # Install VSCodium
        echo " | -- Installing VSCodium..."
        eval "$install_cmd codium"
    fi
else
    echo "${green} | -- At least one of Visual Studio Code (code) or Codium is already installed.${reset}"
fi

# Path to the .zshrc file
ZSHRC_PATH="$HOME/.zshrc"

echo "${bold}${headline_color}Checking if $ZSHRC_PATH exists...${reset}"

# Check if .zshrc exists
if [ -f "$ZSHRC_PATH" ]; then
    echo "${green} | -- $ZSHRC_PATH already exists, no change${reset}"
else
    echo "${yellow} | -- $ZSHRC_PATH does not exist, creating it...${reset}"
    touch $ZSHRC_PATH
fi

echo "${bold}${headline_color}Ensure the correct code / codium alias is present in .zshrc${reset}"

# Check for alias in .zshrc
if ! is_code_installed && is_codium_installed ; then
    echo " | -- Codium is installed, code is not. Checking for alias..."
    if grep -q "alias code=codium" "$ZSHRC_PATH"; then
        echo "${green} | -- Alias 'code=codium' already present in $ZSHRC_PATH.${reset}"
    else
        echo "${yellow} | -- Adding alias 'code=codium' to $ZSHRC_PATH...${reset}"
        echo "alias code=codium" >> "$ZSHRC_PATH"
    fi
else
    echo "${green} | -- No need to add Codium alias${reset}"
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
echo "${bold}${headline_color}Ensure the correct cdd function for ranger launch is present in .zshrc${reset}"

# Check for function in .zshrc
if grep -q "function cdd" "$ZSHRC_PATH"; then
    echo "${green} | -- Function already present in $ZSHRC_PATH.${reset}"
else
    echo "${yellow} | -- Adding function 'cdd' for ranger launch to $ZSHRC_PATH...${reset}"
    echo "$cdd_function" >> "$ZSHRC_PATH"
fi

# Add aliases to .zshrc if not already present
if ! grep -q "alias lss" "$HOME/.zshrc"; then
    echo "alias lss='ls -lia --group-directories-first --color=auto'" >> "$HOME/.zshrc"
fi
if ! grep -q "alias zshrc" "$HOME/.zshrc"; then
    echo "alias zshrc='code ~/.zshrc'" >> "$HOME/.zshrc"
fi

exec zsh
