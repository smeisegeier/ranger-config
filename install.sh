#!/bin/zsh

# color codes
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
        echo " | -- install-posh.sh not found or not executable."
    fi
else
    echo " | -- skipping oh-my-posh installation."
fi


# determine the os
os_name=$(uname)

# set package manager based on os
if [[ "$os_name" == "Darwin" ]]; then
    echo "${bold}${headline_color}found macos. using homebrew (brew) for package installation.${reset}"
    package_manager="brew"
else
    echo "${bold}${headline_color}found linux. using apt for package installation.${reset}"
    package_manager="sudo apt"
fi

chmod +x scripts/helper.sh
source scripts/helper.sh

# linux-specific tasks: replace ranger commands with linux specific ones
if [[ "$os_name" == "Linux" ]]; then
    replace_string_in_file rc.conf "du -d 3 -h" "du --max-depth=1 -h --apparent-size"
fi

# function to check if visual studio code (code) is installed
is_code_installed() {
    command -v code > /dev/null 2>&1
}

# function to check if the codeium extension is installed in vs code
is_codium_installed() {
    command -v codium > /dev/null 2>&1
}

echo "${bold}${headline_color}checking if visual studio code (code) or codium is installed...${reset}"

# check both conditions and print results
if ! is_code_installed && ! is_codium_installed; then
    echo "${yellow} | -- neither visual studio code (code) nor the codeium extension is installed.${reset}"
    echo " | -- installing visual studio code..."

    # update package list and install dependencies
    echo " | -- updating package list..."
    if [[ "$package_manager" == "sudo apt" ]]; then
        sudo apt update
    fi

    echo " | -- installing dependencies..."
    $package_manager install -y software-properties-common apt-transport-https wget

    # macos-specific tasks
    if [[ "$package_manager" == "brew" ]]; then
        echo " | -- installing vscodium using homebrew..."
        brew install --cask vscodium
    else
        echo " | -- adding vscodium repository key..."
        sudo wget https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg -O /usr/share/keyrings/vscodium-archive-keyring.asc

        echo " | -- adding vscodium repository to sources list..."
        echo 'deb [ signed-by=/usr/share/keyrings/vscodium-archive-keyring.asc ] https://paulcarroty.gitlab.io/vscodium-deb-rpm-repo/debs vscodium main' | sudo tee /etc/apt/sources.list.d/vscodium.list

        # update package list again
        echo " | -- updating package list again..."
        sudo apt update

        # install visual studio code
        echo " | -- installing vscodium..."
        sudo apt install -y codium
    fi
else
    echo "${green} | -- at least one of visual studio code (code) or codium is already installed.${reset}"
fi

# path to the .zshrc file
ZSHRC_PATH="$HOME/.zshrc"

echo "${bold}${headline_color}checking if $ZSHRC_PATH exists...${reset}"

# check if .zshrc exists
if [ -f "$ZSHRC_PATH" ]; then
    echo "${green} | -- $ZSHRC_PATH already exists, no change${reset}"
else
    echo "${yellow} | -- $ZSHRC_PATH does not exist, creating it...${reset}"
    touch $ZSHRC_PATH
fi

echo "${bold}${headline_color}ensure the correct code / codium alias is present in .zshrc${reset}"

# check for alias in .zshrc
if ! is_code_installed && is_codium_installed ; then
    echo " | -- codium is installed, code is not. checking for alias.."
    if grep -q "alias code=codium" "$ZSHRC_PATH"; then
        echo "${green} | -- alias 'code=codium' already present in $ZSHRC_PATH.${reset}"
    else
        echo "${yellow} | -- adding alias 'code=codium' to $ZSHRC_PATH...${reset}"
        echo "alias code=codium" >> "$ZSHRC_PATH"
    fi
else
    echo "${green} | -- no need to add codium alias${reset}"
fi

# define the function to be added to .zshrc
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
echo "${bold}${headline_color}ensure the correct cdd function for ranger launch is present in .zshrc${reset}"

# check for function in .zshrc
if grep -q "function cdd" "$ZSHRC_PATH"; then
    echo "${green} | -- function already present in $ZSHRC_PATH.${reset}"
else
    echo "${yellow} | -- adding function 'cdd' for ranger launch to $ZSHRC_PATH...${reset}"
    echo "$cdd_function" >> "$ZSHRC_PATH"
fi


if ! grep -q "alias lss" "$HOME/.zshrc"; then
    echo "alias lss='ls -lia --group-directories-first --color=auto'" >> "$HOME/.zshrc"
fi
if ! grep -q "alias zshrc" "$HOME/.zshrc"; then
    echo "alias zshrc='code ~/.zshrc'" >> "$HOME/.zshrc"
fi