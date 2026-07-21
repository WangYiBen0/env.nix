# Modules

## Profile System

Profiles control which features are enabled per host. Set in the host's `default.nix`:

```nix
machine.profiles.desktop = true;  # Plasma6, niri, hyprland, steam, fonts, IME, etc.
machine.profiles.server = true;   # (reserved for future use)
```

Shared modules (overlays, packages, nix, system, services, dae) are always loaded regardless of profile.

## What Each Profile Enables

### Desktop Profile

**NixOS level:**

- Plasma6 + login manager
- niri, hyprland
- Steam + gamescope + protontricks + extest
- System fonts (Noto, Maple Mono, JetBrains Mono, etc.)
- Flatpak, nix-ld, podman

**Home Manager level:**

- Kitty terminal
- Fcitx5 + RIME + rime-ice
- Anyrun / Fuzzel launcher
- User fonts (Apple Fonts, LXGW series)
- GTK/Qt theme (WhiteSur + Catppuccin)
- XDG user directories
- Niri compositor config
- Zen browser, swaync, polkit agent

## Directory Structure

```
modules/
├── common/                   # Shared between NixOS and Home Manager
│   ├── default.nix           # Auto-imports all .nix via scanNixFiles
│   ├── overlays.nix          # Applies project overlays at NixOS level
│   └── packages.nix          # Shared system packages (git, neovim, fish, nh, etc.)
├── nixos/                    # NixOS system-level modules
│   ├── default.nix           # Auto-imports all .nix via scanNixFiles
│   ├── nix.nix               # Nix settings, caches, GC
│   ├── system.nix            # Networking, timezone, locale, boot
│   ├── services.nix          # PipeWire, SSH, Bluetooth, firewall
│   ├── dae.nix               # dae/dae proxy
│   ├── compat.nix            # nix-ld, flatpak, podman, Wine (desktop only)
│   ├── font.nix              # System fonts (desktop only)
│   └── profiles/
│       ├── default.nix       # Auto-imports profile modules
│       ├── desktop.nix       # Desktop option definition + config
│       └── server.nix        # Server option definition
└── home/                     # Home Manager user-level modules
    ├── default.nix           # Auto-imports all .nix via scanNixFiles
    ├── nix.nix               # HM nix settings
    ├── shell.nix             # Bash, Fish, Bat, Eza, Zellij, Zoxide, aliases
    ├── starship.nix          # Starship prompt
    ├── git.nix               # Git config
    ├── editor.nix            # Nixvim
    ├── packages.nix          # User packages
    ├── yazi.nix              # Yazi file manager + plugins
    ├── niri.nix              # Niri compositor config
    ├── kitty.nix             # Kitty terminal (desktop only)
    ├── theme.nix             # Cursor, GTK, Qt, Catppuccin (desktop only)
    ├── ime.nix               # Fcitx5 + Rime (desktop only)
    ├── font.nix              # User fonts + fontconfig (desktop only)
    ├── launcher.nix          # Anyrun + Fuzzel (desktop only)
    ├── variable.nix          # Session variables (desktop only)
    ├── directory.nix         # XDG user dirs (desktop only)
    ├── nix-index.nix         # nix-index + comma
    ├── kitty/                # Kitten scripts (scroll_mark.py, search.py)
    ├── niri/                 # Niri config.kdl
    └── profiles/
        ├── default.nix       # Auto-imports profile modules
        ├── desktop.nix       # Desktop option definition + extra config
        └── server.nix        # Server option definition
```

All modules use `scanNixFiles` for auto-discovery. Desktop-only modules are gated with `mkIf config.machine.profiles.desktop`.

## Loading Order

1. `modules/common/` — loaded first (overlays, shared packages)
2. `modules/nixos/` or `modules/home/` — loaded by host configs
3. Host-specific overrides — loaded last (highest priority)
