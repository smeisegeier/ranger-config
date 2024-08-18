#!/bin/bash

# # -- Setup Alias in $HOME/zsh/aliasrc
# git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
# echo 'source ~/powerlevel10k/powerlevel10k.zsh-theme' >> ~/.zshrc

# Exit on any error
set -e

# Define the path to the theme file
theme_file="$HOME/powerlevel10k_rainbow.omp.json"

# Initialize oh-my-posh with the downloaded theme file and start zsh
if grep -q "oh-my-posh init zsh" "$HOME/.zshrc"; then
    echo "oh-my-posh is already initialized in $HOME/.zshrc"
else
    echo "Initializing oh-my-posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s

    # Download the theme file only if it does not exist
    if [ ! -f "$theme_file" ]; then
        echo "Downloading theme file..."
        curl -s -o "$theme_file" https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/powerlevel10k_rainbow.omp.json
    fi
    echo -e "\neval \"\$(oh-my-posh init zsh --config $theme_file)\"" >> "$HOME/.zshrc"
    # Start a new zsh session
    exec zsh
fi