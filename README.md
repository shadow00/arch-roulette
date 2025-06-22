# Arch Roulette
A game that randomly installs or removes packages from your Arch Linux system.

## Features
- Randomly installs packages from official repositories or AUR
- Randomly removes installed packages
- Supports dry-run mode to preview changes
- Safe mode for confirmation before actions
- Comprehensive logging system
- AUR support via paru (optional)

## Installation
```bash
# From AUR
paru -S arch-roulette

# From source
git clone https://github.com/shadow00/arch-roulette.git
cd arch-roulette
makepkg -si
```

## Usage
```bash
# Normal mode
arch-roulette

# Dry run mode (preview changes)
arch-roulette --dry-run

# Safe mode (confirm before changes)
arch-roulette --safe-mode

# AUR support (requires paru)
arch-roulette --hardcore
```

## License
Arch Roulette is licensed under the GNU General Public License version 3 (GPLv3).