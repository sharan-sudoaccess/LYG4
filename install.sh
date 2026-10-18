#!/usr/bin/env bash
# One-command setup for Ubuntu (22.04+/24.04) and Arch Linux.
#
#   ./install.sh                 install packages + link configs (theme: gruvbox)
#   ./install.sh --theme nord    pick the starting theme
#   ./install.sh --no-packages   only link configs
#   ./install.sh --uninstall     remove the links and restore your old configs
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"
BIN="$HOME/.local/bin"
THEME="gruvbox"
PACKAGES=1
UNINSTALL=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --theme)       THEME="$2"; shift 2 ;;
        --no-packages) PACKAGES=0; shift ;;
        --uninstall)   UNINSTALL=1; shift ;;
        *) echo "unknown option: $1"; exit 1 ;;
    esac
done

say() { printf '\033[1;33m==>\033[0m %s\n' "$*"; }

install_packages() {
    # shellcheck source=/dev/null
    . /etc/os-release
    case " $ID $ID_LIKE " in
        *" arch "*)
            say "Arch detected — installing with pacman"
            sudo pacman -S --needed --noconfirm \
                i3-wm i3lock polybar rofi kitty picom dunst feh maim xclip \
                xdotool libnotify libpulse imagemagick xorg-xsetroot \
                network-manager-applet blueman pavucontrol brightnessctl xorg-xinput \
                libinput python git curl xdg-user-dirs ttf-jetbrains-mono ttf-jetbrains-mono-nerd
            ;;
        *" ubuntu "*|*" debian "*)
            say "Ubuntu/Debian detected — installing with apt"
            sudo apt-get update
            sudo apt-get install -y \
                i3-wm i3lock polybar rofi kitty picom dunst feh maim xclip \
                xdotool libnotify-bin pulseaudio-utils imagemagick \
                network-manager-gnome blueman pavucontrol brightnessctl xinput \
                libinput-tools python3 git curl x11-xserver-utils xdg-user-dirs fonts-jetbrains-mono
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

# Icons in the bar need a Nerd Font. Arch gets it from pacman; elsewhere we
# download JetBrainsMono Nerd Font into ~/.local/share/fonts (user only).
install_font() {
    fc-list 2>/dev/null | grep -qi "Nerd Font" && return
    say "Installing JetBrainsMono Nerd Font (icons for the bar)"
    local dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    mkdir -p "$dir"
    if curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/JetBrainsMono.tar.xz" \
        | tar -xJ -C "$dir"; then
        fc-cache -f "$dir" >/dev/null
    else
        echo "   could not download the font — bar icons will show as boxes"
    fi
}

# Touchpad gestures (libinput-gestures, pinned release). It reads the touchpad,
# so the user has to be in the "input" group — that needs a logout/login once.
GESTURES_VERSION=2.81
install_gestures() {
    if ! command -v libinput-gestures >/dev/null; then
        say "Installing libinput-gestures $GESTURES_VERSION (touchpad gestures)"
        local src="${XDG_CACHE_HOME:-$HOME/.cache}/devdesk/libinput-gestures"
        rm -rf "$src"
        git -c advice.detachedHead=false clone -q --depth 1 --branch "$GESTURES_VERSION" \
            https://github.com/bulletmark/libinput-gestures "$src"
        (cd "$src" && sudo ./libinput-gestures-setup install >/dev/null)   # must run from its folder
    fi
    if ! id -nG "$USER" | grep -qw input; then
        sudo gpasswd -a "$USER" input >/dev/null
        NEED_RELOGIN=1
    fi
}

uninstall() {
    local link dest backup
    for link in "$CFG"/{i3,polybar,picom,dunst} "$CFG"/devdesk/{kitty,rofi} \
                "$CFG"/libinput-gestures.conf "$BIN"/dt-*; do
        [[ -L $link && "$(readlink -f "$link")" == "$REPO"/* ]] || continue
        rm "$link"; echo "   removed $link"
    done
    for dest in "$CFG"/{i3,polybar,picom,dunst}; do
        backup=$(find "$(dirname "$dest")" -maxdepth 1 -name "$(basename "$dest").bak.*" | sort | tail -1)
        if [[ -n $backup && ! -e $dest ]]; then mv "$backup" "$dest"; echo "   restored $dest"; fi
    done
    say "Uninstalled. Packages were left in place."
}

if [[ $UNINSTALL == 1 ]]; then uninstall; exit 0; fi
NEED_RELOGIN=0
if [[ $PACKAGES == 1 ]]; then install_packages; install_gestures; fi
install_font

say "Linking configs"
mkdir -p "$CFG" "$BIN"
for dir in i3 polybar picom dunst; do
    link "$REPO/config/$dir" "$CFG/$dir"
done
# kitty and rofi get private config dirs, so ~/.config/kitty and ~/.config/rofi
# (used by other desktops like Hyprland or GNOME) are never touched
mkdir -p "$CFG/devdesk"
for dir in kitty rofi; do
    link "$REPO/config/$dir" "$CFG/devdesk/$dir"
done
link "$REPO/config/gestures/libinput-gestures.conf" "$CFG/libinput-gestures.conf"

say "Linking scripts into $BIN"
for s in "$REPO"/scripts/dt-*; do
    link "$s" "$BIN/$(basename "$s")"
done

mkdir -p "$HOME/Pictures/Screenshots"

say "Applying theme: $THEME"
"$BIN/dt-theme" set "$THEME"

say "Done! Log out, pick 'i3' on the login screen and log back in."
say "Super+Enter terminal · Super+d apps · Super+t themes · Super+/ all shortcuts"
if [[ $NEED_RELOGIN == 1 ]]; then
    say "Touchpad gestures start working after you log out and back in once."
fi
