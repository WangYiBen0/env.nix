# Hosts

## Managed Machines

| Host          | Machine Type | Profile | NixOS Version | Description        |
| ------------- | ------------ | ------- | ------------- | ------------------ |
| `matebook16d` | MateBook 16D | desktop | 26.11         | Primary laptop     |
| `sxyz-89`     | School PC    | desktop | 26.05         | School workstation |
| `sxyz-9`      | School PC    | desktop | 26.05         | School workstation |

## Directory Structure

```
hosts/
├── default.nix                  # Discovers arch directories, filters for linux, merges nixosConfigurations
└── x86_64-linux/
    ├── default.nix              # Scans host directories, generates per-host nixosSystem
    ├── matebook16d/
    │   ├── default.nix          # Host entry: imports boot/disk/hw/home, sets profile
    │   ├── bootloader.nix
    │   ├── disko.nix            # Disko disk layout
    │   ├── hardware.nix
    │   ├── home.nix             # Home Manager NixOS module setup
    │   ├── hostname.nix
    │   ├── state-version.nix
    │   ├── home/                # User HM configs (auto-scanned)
    │   │   ├── nixos-module.nix # Registers home-manager.users, imports user nixos-modules
    │   │   └── w1ngd1nga5ter/
    │   │       ├── default.nix           # Imports modules/home, sets profile
    │   │       ├── nixos-module/
    │   │       │   └── default.nix       # users.users / users.groups definition
    │   │       ├── standalone/
    │   │       │   └── default.nix       # home.username / home.homeDirectory
    │   │       └── state-version.nix
    │   └── persistent/          # Preservation paths
    ├── sxyz-89/                 # (same structure as matebook16d)
    └── sxyz-9/
```

## Host Auto-Discovery

The build system automatically discovers hosts, architectures, and users:

1. `hosts/default.nix` scans subdirectories for architecture directories (e.g. `x86_64-linux`)
2. `hosts/<arch>/default.nix` scans subdirectories for host directories
3. Each host's `home/` is scanned for user directories
4. Each `home/<username>/standalone/` generates a standalone HM output
5. Each `home/<username>/nixos-module/` registers a `home-manager.users.<name>`

To add a new host, create a directory under `hosts/<arch>/` with the required structure.
