# Modules

## Module System

The module system uses two layers:

1. **Profiles** — high-level presets that set multiple module options at once
2. **Modules** — individual features with their own enable options

Set a profile in the host's `default.nix`:

```nix
machine.profiles.desktop = true;  # enables niri, kitty, fonts, IME, etc.
machine.profiles.server = true;   # (reserved for future use)
```

Or enable individual modules directly:

```nix
machine.modules.niri.enable = true;
machine.modules.kitty.enable = true;
machine.modules.font.enable = true;
```

## Option Definitions

All `machine.*` options are defined in `modules/common/options.nix` (single source of truth). Profiles set module options, and modules check their own enable options.

## What Each Module Enables

### NixOS Modules

| Module | Option                          | Description                                           |
| ------ | ------------------------------- | ----------------------------------------------------- |
| font   | `machine.modules.font.enable`   | System fonts (Noto, Maple Mono, JetBrains Mono, etc.) |
| compat | `machine.modules.compat.enable` | nix-ld, flatpak, podman, Wine                         |
| dae    | `machine.modules.dae.enable`    | dae/dae proxy                                         |

### Home Manager Modules

| Module    | Option                             | Description                 |
| --------- | ---------------------------------- | --------------------------- |
| niri      | `machine.modules.niri.enable`      | Niri compositor config      |
| kitty     | `machine.modules.kitty.enable`     | Kitty terminal              |
| font      | `machine.modules.font.enable`      | User fonts + fontconfig     |
| ime       | `machine.modules.ime.enable`       | Fcitx5 + RIME + rime-ice    |
| launcher  | `machine.modules.launcher.enable`  | Fuzzel launcher             |
| theme     | `machine.modules.theme.enable`     | Cursor, GTK, Qt, Catppuccin |
| directory | `machine.modules.directory.enable` | XDG user directories        |
| variable  | `machine.modules.variable.enable`  | Desktop session variables   |

### Always-Loaded Modules

Shared modules (overlays, packages, nix, system, services) are always loaded regardless of profile.

## Directory Structure

```
modules/
├── common/                   # Shared between NixOS and Home Manager
│   ├── default.nix           # Auto-imports all .nix via scanNixFiles
│   ├── options.nix           # All machine.* option definitions
│   ├── overlays.nix          # Applies project overlays at NixOS level
│   └── nix.nix               # Nix settings, caches, GC
├── nixos/                    # NixOS system-level modules
│   ├── default.nix           # Auto-imports all .nix via scanNixFiles
│   ├── modules.nix           # External module imports (home-manager, niri)
│   ├── nix.nix               # Nix channel config
│   ├── system.nix            # Networking, timezone, locale, boot
│   ├── packages.nix          # System packages
│   ├── services.nix          # PipeWire, SSH, Bluetooth, firewall
│   ├── dae.nix               # dae/dae proxy (gated: machine.modules.dae.enable)
│   ├── compat.nix            # nix-ld, flatpak, podman, Wine (gated: machine.modules.compat.enable)
│   ├── font.nix              # System fonts (gated: machine.modules.font.enable)
│   └── profiles/
│       ├── default.nix       # Imports all profiles
│       ├── desktop.nix       # Sets module options for desktop
│       └── server.nix        # (reserved)
├── home/                     # Home Manager user-level modules
│   ├── default.nix           # Auto-imports all .nix via scanNixFiles
│   ├── modules.nix           # External module imports (catppuccin, nixvim, zen)
│   ├── nix.nix               # HM nix settings
│   ├── shell.nix             # Bash, Fish, Bat, Eza, Zellij, Zoxide, aliases
│   ├── starship.nix          # Starship prompt
│   ├── git.nix               # Git config
│   ├── editor.nix            # Nixvim
│   ├── packages.nix          # User packages
│   ├── yazi.nix              # Yazi file manager + plugins
│   ├── nix-index.nix         # nix-index + comma
│   ├── niri.nix              # Niri config (gated: machine.modules.niri.enable)
│   ├── kitty.nix             # Kitty terminal (gated: machine.modules.kitty.enable)
│   ├── theme.nix             # GTK/Qt theme (gated: machine.modules.theme.enable)
│   ├── ime.nix               # Fcitx5 (gated: machine.modules.ime.enable)
│   ├── font.nix              # User fonts (gated: machine.modules.font.enable)
│   ├── launcher.nix          # Fuzzel (gated: machine.modules.launcher.enable)
│   ├── variable.nix          # Session variables (gated: machine.modules.variable.enable)
│   ├── directory.nix         # XDG user dirs (gated: machine.modules.directory.enable)
│   ├── kitty/                # Kitten scripts (scroll_mark.py, search.py)
│   └── profiles/
│       ├── default.nix       # Imports all profiles
│       ├── desktop.nix       # Sets module options for desktop
│       └── server.nix        # (reserved)
├── home-standalone/          # Standalone Home Manager modules
└── home-as-module/           # Home Manager as NixOS module
```

## Loading Order

1. `modules/common/` — loaded first (options, overlays, shared packages)
2. `modules/nixos/` or `modules/home/` — loaded by host configs
3. Profile sets module options → modules check their enable options
4. Host-specific overrides — loaded last (highest priority)
