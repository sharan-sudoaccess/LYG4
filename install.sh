#!/usr/bin/env bash
# One-command setup for Ubuntu (22.04+/24.04) and Arch Linux.
#
#   ./install.sh                 install packages + link configs (theme: gruvbox)
#   ./install.sh --theme nord    pick the starting theme
#   ./install.sh --no-packages   only link configs
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
THEME="gruvbox"
PACKAGES=1

while [[ $# -gt 0 ]]; do
    case $1 in
        --theme)       THEME="$2"; shift 2 ;;
        --no-packages) PACKAGES=0; shift ;;
        *) echo "unknown option: $1"; exit 1 ;;
    esac
done

say() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

install_packages() {
    . /etc/os-release
    case " $ID $ID_LIKE " in
        *" arch "*)
            say "Arch detected — installing with pacman"
            sudo pacman -S --needed --noconfirm \
                i3-wm i3lock polybar rofi kitty picom dunst feh maim xclip \
                xdotool libnotify libpulse xorg-xsetroot xdg-user-dirs ttf-jetbrains-mono
            ;;
        *" ubuntu "*|*" debian "*)
            say "Ubuntu/Debian detected — installing with apt"
            sudo apt-get update
            sudo apt-get install -y \
                i3-wm i3lock polybar rofi kitty picom dunst feh maim xclip \
                xdotool libnotify-bin pulseaudio-utils x11-xserver-utils xdg-user-dirs fonts-jetbrains-mono
            ;;
        *)
            echo "Unsupported distro ($ID). Install the packages from README manually, then run with --no-packages."
            exit 1 ;;
    esac
}

link() {  # link <src> <dest>, backing up anything already there
    local src=$1 dest=$2
    if [[ -e $dest || -L $dest ]] && [[ "$(readlink -f "$dest")" != "$src" ]]; then
        mv "$dest" "$dest.bak.$(date +%s)"
        echo "   backed up $dest"
    fi
    ln -sfn "$src" "$dest"
    echo "   $dest -> $src"
}

[[ $PACKAGES == 1 ]] && install_packages

say "Linking configs"
mkdir -p "$CFG" "$BIN"
for dir in i3 polybar rofi kitty picom dunst; do
    link "$REPO/config/$dir" "$CFG/$dir"
done

say "Linking scripts into $BIN"
for s in "$REPO"/scripts/dt-*; do
    link "$s" "$BIN/$(basename "$s")"
done

mkdir -p "$HOME/Pictures/Screenshots"

say "Applying theme: $THEME"
"$BIN/dt-theme" set "$THEME"

say "Done! Log out, pick 'i3' on the login screen and log back in."
say "Press Super+Return for a terminal, Super+d for apps, Super+t to change theme."
