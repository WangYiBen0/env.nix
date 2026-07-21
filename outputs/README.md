# Outputs

## Flake Outputs

| Output                             | Description                                                        |
| ---------------------------------- | ------------------------------------------------------------------ |
| `nixosConfigurations.<host>`       | NixOS system configs (NixOS module HM included)                    |
| `homeConfigurations.<user>@<host>` | Standalone HM configs (for debugging)                              |
| `packages.<system>`                | Custom packages built from `pkgs/` (fonts, agent, etc.)            |
| `packages.<system>.fonts.<name>`   | Font packages (alias: `packages.<system>.<name>`)                  |
| `overlays.default`                 | Project overlay (adds custom packages to nixpkgs)                  |
| `lib`                              | Custom lib (scanNixFiles, scanPackages, listSubDir, lastAfterDash) |
| `formatter.<system>`               | nixfmt                                                             |
| `checks.<system>.pre-commit`       | Pre-commit hooks (nixfmt, deadnix, statix, typos, prettier)        |
| `devShells.<system>.default`       | Dev shell with linting tools                                       |

## Deployment

### NixOS module mode (recommended)

Home Manager is integrated as a NixOS module. One command builds everything:

```bash
nh os switch .
```

### Standalone mode (for debugging)

Standalone Home Manager configurations are also generated:

```bash
nh home switch -- --flake .#w1ngd1nga5ter@matebook16d
```

## Custom Packages

Custom packages live in `pkgs/` and are auto-discovered by `lib.scanPackages`:

```
pkgs/
├── fonts/
│   ├── lxgw-neozhisong/   # LXGW Neo ZhiSong
│   ├── lxgw-zhenkai/      # LXGW ZhenKai GB
│   └── zhuque-fangsong/   # Zhuque FangSong
└── agent/
    └── miyu/              # Miyu AI agent
```

Build individual packages:

```bash
nix build .#miyu                    # Build agent
nix build .#fonts.lxgw-zhenkai      # Build font (namespaced)
nix build .#lxgw-zhenkai            # Build font (top-level alias)
```

The overlay (`overlays/packages.nix`) also makes these available system-wide via `pkgs.*` and `pkgs.fonts.*`.

## Overlays

Overlays are defined in `overlays/` and auto-merged by `overlays/default.nix`. Currently:

- `overlays/packages.nix` — Adds custom packages from `pkgs/` to nixpkgs

New overlay files added to `overlays/` are automatically picked up.

## Add a New Host

1. Create a directory under `hosts/<arch>/<hostname>/`
2. Add the required files:
   - `default.nix` — Host-specific NixOS config + `machine.profiles.desktop = true`
   - `hardware.nix` — Hardware config (copy from an existing host as reference)
   - `home.nix` — Home Manager NixOS module setup
   - `home/` — User home directory (copy from an existing host and adjust)
3. Copy one of the existing hosts as a template and adjust:
   - `networking.hostName`
   - `hardware.nix`
   - Boot configuration
   - `state-version.nix`

The build system auto-discovers hosts, architectures, and users via `lib.scanNixFiles`, `lib.listSubDir`, and `lib.scanPackages`.

## Flake Inputs

| Input                | Description                                  |
| -------------------- | -------------------------------------------- |
| `nixpkgs`            | NixOS unstable channel                       |
| `home-manager`       | User environment manager                     |
| `apple-fonts`        | SF Pro, SF Mono, New York                    |
| `catppuccin`         | Catppuccin theme suite                       |
| `daeuniverse`        | dae proxy                                    |
| `disko`              | Declarative disk partitioning                |
| `haumea`             | Filesystem-based module system               |
| `niri`               | Niri Wayland compositor                      |
| `nix-gaming`         | Gaming-related packages                      |
| `nix-index-database` | Prebuilt nix-index database                  |
| `nixpak`             | Sandboxing with Nix                          |
| `nixvim`             | Neovim configuration framework (custom fork) |
| `preservation`       | State persistence                            |
| `zen-browser`        | Zen browser                                  |
| `git-hooks`          | Pre-commit hooks                             |

## Development

```bash
nix develop    # Enter dev shell with linting tools
nix fmt        # Format all files
nix flake check # Run pre-commit checks
```

## Caches

Pre-configured substituters:

- `cache.garnix.io`
- `nix-community.cachix.org`
- `catppuccin.cachix.org`
- `nixpkgs-python.cachix.org`
- `niri.cachix.org`
- Chinese mirrors: tuna, ustc, cernet
- `cache.nixos.org`
