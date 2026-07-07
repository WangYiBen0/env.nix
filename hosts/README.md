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
├── default.nix              # Scans arch subdirectories
├── default/                  # Shared host-level modules (always loaded)
│   ├── default.nix
│   ├── dae.nix              # dae proxy config
│   ├── packages.nix         # Shared system packages
│   └── system.nix           # Shared system settings
└── x86_64-linux/
    ├── default.nix           # Generates nixosConfigurations for all hosts
    ├── matebook16d/          # Host-specific overrides
    │   ├── default.nix
    │   ├── dae.nix
    │   ├── disk.nix          # Disko disk layout
    │   ├── hardware.nix
    │   ├── home.nix          # Home Manager NixOS module
    │   ├── system.nix
    │   ├── home/             # User HM configs (auto-scanned)
    │   └── persistent/       # Persistence paths
    ├── sxyz-89/
    └── sxyz-9/
```

## Host Auto-Discovery

The build system automatically discovers hosts and users:

1. `hosts/x86_64-linux/default.nix` scans subdirectories for a `home/` folder
2. Each `home/<username>/standalone/` directory generates a standalone HM output
3. Each `home/<username>/nixos-module/` directory registers a `home-manager.users.<name>`

To add a new host, just create a directory under `hosts/x86_64-linux/` with the required structure.
