# ranger-config

## why

## usage

### prerequisites

**all os**
if nerdfonts are not installed, you might consider installing one like the hack nerd font:

```bash
sudo apt install wget fontconfig
```

```bash
wget -P ~/.local/share/fonts https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/Hack.zip \
 && cd ~/.local/share/fonts && unzip Hack.zip && rm *Windows* && rm Hack.zip && fc-cache -fv
```

[![windows](https://badgen.net/badge/icon/windows?icon=windows&label)](https://microsoft.com/windows/)
ranger can be run on WSL2

![macos](https://img.shields.io/badge/macOS-blue?logo=apple&logoColor=white&labelColor=grey)
have brew installed

```bash
# check if brew is installed
brew -v
```

```bash
# if no version is shown
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

![linux](https://img.shields.io/badge/linux-blue?logo=linux&logoColor=white&labelColor=grey)
(debian)
zsh must be present

### installation

🚨 check if the 'ranger' folder exists. if so - create backup as `.zip` file of previous folder. no data is lost!

```bash
cd ~/.config
if [[ -d "$HOME/.config/ranger" ]]; then
    zip -r ranger.zip ranger && rm -rf ranger/
fi

git clone https://github.com/smeisegeier/ranger-config ~/.config/ranger/

cd ~/.config/ranger/
chmod +x install.sh
```

now the install script can be run

```bash
$HOME/.config/ranger/install.sh
```
