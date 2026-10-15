# devdesk — my keyboard-driven i3 setup

A small, clean developer desktop built on **i3**. It works on both **Ubuntu** and **Arch Linux**.
Every part of the desktop (terminal, launcher, bar, window borders, notifications, wallpaper)
uses the same colors, and one command switches all of them between **3 themes**.

| Gruvbox | Nord | Catppuccin |
|---|---|---|
| ![gruvbox](screenshots/gruvbox.png) | ![nord](screenshots/nord.png) | ![catppuccin](screenshots/catppuccin.png) |

![rofi launcher](screenshots/rofi-launcher.png)

## What's inside

| Part | Tool | Config |
|---|---|---|
| Window manager | i3 | `config/i3/config` |
| Status bar | polybar | `config/polybar/` |
| Launcher | rofi | `config/rofi/config.rasi` |
| Terminal | kitty | `config/kitty/kitty.conf` |
| Compositor | picom (shadows, fades, round corners) | `config/picom/picom.conf` |
| Notifications | dunst | `config/dunst/dunstrc.base` |
| Screenshots | maim + xclip | `scripts/dt-shot` |

I kept it small on purpose: no icon fonts, no heavy widgets, just the tools you actually use.

## Install (one command)

```bash
git clone https://github.com/sharan-sudoaccess/LYG4.git ~/devdesk
cd ~/devdesk
./install.sh                 # or: ./install.sh --theme nord
```

`install.sh` will:
1. find out if you're on Arch (`pacman`) or Ubuntu/Debian (`apt`) and install the packages
2. back up any existing configs (`~/.config/i3` → `~/.config/i3.bak.<time>`)
3. symlink the configs into `~/.config` and the scripts into `~/.local/bin`
4. apply the starting theme

Then log out, choose **i3** on the login screen and log back in.

Already have the packages? Run `./install.sh --no-packages`.

> **Ubuntu note:** use Ubuntu 24.04 or newer. `gaps` only became part of i3 in 4.22, and
> 22.04 ships 4.20. On 22.04, delete the three `gaps`/`smart_gaps` lines in `config/i3/config`.

## Keybindings

`Super` is the mod key.

| Keys | Action |
|---|---|
| `Super + Enter` | terminal (kitty) |
| `Super + d` | app launcher (rofi) |
| `Super + Tab` | switch between open windows (rofi) |
| `Super + 1..9` | go to workspace |
| `Super + Shift + 1..9` | move window to workspace |
| `Super + [` / `]` | previous / next workspace |
| ``Super + ` `` | jump back to the last workspace |
| `Super + h j k l` (or arrows) | focus window |
| `Super + Shift + h j k l` | move window |
| `Super + b` / `v` | split horizontal / vertical |
| `Super + w` / `s` / `e` | tabbed / stacked / split layout |
| `Super + Shift + f` | fullscreen |
| `Super + Shift + Space` | toggle floating |
| `Super + r` | resize mode (`hjkl`, `Esc` to leave) |
| `Super + q` | close window |
| `Print` | screenshot: full screen |
| `Shift + Print` or `Super + Shift + s` | screenshot: select area |
| `Super + Print` | screenshot: active window |
| `Super + t` | theme picker |
| `Super + i` | system info notification |
| `Super + Shift + i` | live system monitor (floating) |
| `Super + f` | focus mode on/off |
| `Super + Shift + x` | lock screen |
| `Super + Shift + c` / `r` | reload / restart i3 |
| `Super + Shift + e` | exit i3 |

Screenshots go to `~/Pictures/Screenshots/` and are also copied to the clipboard.

## Scripts

All scripts are plain bash and live in `scripts/`.

### `dt-theme`: switch theme everywhere

```bash
dt-theme set nord      # gruvbox | nord | catppuccin
dt-theme menu          # pick one with rofi (Super+t)
dt-theme list
```

Each theme is a short file in `themes/` with a few named colors (`bg`, `fg`, `accent`, ...)
plus the 16 terminal colors. `dt-theme` turns those into small color files for each app:

```
themes/nord.theme ──► ~/.config/i3/theme.conf      (window borders)
                  ├─► ~/.config/kitty/colors.conf  (terminal)
                  ├─► ~/.config/polybar/colors.ini (bar)
                  ├─► ~/.config/rofi/colors.rasi   (launcher)
                  ├─► ~/.config/dunst/dunstrc      (notifications)
                  └─► themes/wallpapers/nord.jpg   (wallpaper)
```

Then it reloads everything that's running: i3, polybar, kitty (with `SIGUSR1`, so open
terminals change color too) and dunst. You don't need to log out.

**Adding your own theme:** copy `themes/nord.theme`, change the colors, and optionally drop a
wallpaper with the same name into `themes/wallpapers/`. It will show up in the picker.

### `dt-sysinfo`: CPU, RAM, battery

```bash
dt-sysinfo            # CPU 12%  RAM 41%  BAT 87%+
dt-sysinfo --watch    # live view with bars, refreshes every 2s (dt-sysinfo --watch 1 for 1s)
dt-sysinfo --notify   # show it as a notification
```

- **CPU** is read from `/proc/stat` (two samples, 0.4s apart)
- **RAM** comes from `/proc/meminfo` (`MemTotal - MemAvailable`)
- **Battery** comes from `/sys/class/power_supply/BAT*` (`+` = charging, `=` = full)
- **No battery (desktop)?** It shows CPU temperature instead, and disk usage if there's no sensor.

The bar runs it every 3 seconds. Click it to get a notification.

### `dt-shot`: screenshots

`dt-shot full | area | window`. It saves a timestamped PNG, copies it to the clipboard and
shows a notification with a preview.

### `dt-focus`: focus mode

A "do not disturb" switch for deep work. It hides the bar, removes gaps and pauses
notifications. Press it again to turn everything back on, and it tells you how many minutes
you stayed focused.

## Extras (bonus points)

- **One-command install** for both Arch and Ubuntu, and it backs up your old configs
- **Automatic workspace assignment:** browsers open on `2:web`, editors/IDEs on `3:code`,
  chat apps on `4:chat`, media on `5:media`. Dialogs and settings windows float.
- **Theme-matched wallpapers:** every theme comes with its own wallpaper and switches it too
- **Live reload:** switching themes recolors terminals that are already open
- **Focus mode** (my own small productivity feature)

## Repo layout

```
.
├── install.sh
├── config/
│   ├── i3/config
│   ├── polybar/{config.ini,launch.sh}
│   ├── rofi/config.rasi
│   ├── kitty/kitty.conf
│   ├── picom/picom.conf
│   └── dunst/dunstrc.base
├── scripts/
│   ├── dt-theme
│   ├── dt-sysinfo
│   ├── dt-shot
│   └── dt-focus
├── themes/
│   ├── gruvbox.theme  nord.theme  catppuccin.theme
│   └── wallpapers/
└── screenshots/
```

Generated color files are in `.gitignore`, so the repo only contains the source configs.

## Uninstall

Remove the symlinks and bring back your backups:

```bash
rm ~/.config/{i3,polybar,rofi,kitty,picom,dunst} ~/.local/bin/dt-*
# then rename the *.bak.<time> folders back if you had old configs
```
