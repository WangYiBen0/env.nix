# Outputs

## Flake Outputs

| Output                             | Description                                                        |
| ---------------------------------- | ------------------------------------------------------------------ |
| `nixosConfigurations.<host>`       | NixOS system configs (NixOS module HM included)                    |
| `homeConfigurations.<user>@<host>` | Standalone HM configs (for debugging)                              |
| `packages.<system>`                | Custom packages built from `pkgs/` (fonts, agent, etc.)            |
| `images.<system>.livecd`           | Bootable rescue/live ISO (see below)                               |
| `images.<system>.livecd-vm`        | Same rescue system as a runnable VM (see below)                    |
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

## Live CD

`images.<system>.livecd` builds a minimal installer image with the tools this
fleet's repair jobs need (btrfs-progs, disko, lsof, rsync, smartmontools) plus
sshd for the headless case — see [`hosts/x86_64-linux/livecd.nix`](../hosts/x86_64-linux/livecd.nix).
It is deliberately neither a `nixosConfiguration` nor a package: CI builds every
one of those on an `outputs/` change, and a ~1.5 GB image should not be in either
list. `nix flake check` only warns about the unknown output.

```bash
nix build .#images.x86_64-linux.livecd
sudo dd if=result/iso/nixos-livecd-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Console login is root with no password (from the installer profile); ssh accepts
root with the key in the module only.

The same system also builds as a VM, which is the cheap way to poke at the
rescue environment without writing a USB stick:

```bash
nix build .#images.x86_64-linux.livecd-vm
./result/bin/run-livecd-vm
```

It runs headless (`virtualisation.vmVariant` in [`images.nix`](images.nix) sets
`graphics = false`), so the console is the serial line; `NIX_DISK_IMAGE=` and
`QEMU_OPTS=` override the throwaway disk and QEMU flags. Without `/dev/kvm`
QEMU falls back to TCG and the boot takes a couple of minutes.

## Custom Packages

Custom packages live in `pkgs/` and are auto-discovered by `lib.scanPackages`:

```
pkgs/
├── fonts/
│   ├── lxgw-neozhisong/   # LXGW Neo ZhiSong
│   ├── lxgw-zhenkai/      # LXGW ZhenKai Slab GB
│   └── zhuque-fangsong/   # Zhuque FangSong
├── networking/
│   ├── honk/              # honk transparent proxy engine
│   └── doona/             # doona web UI for honk
└── agent/
    └── miyu/              # Miyu AI agent
```

Build individual packages:

```bash
nix build .#miyu                    # Build agent
nix build .#lxgw-zhenkai            # Build font
```

The overlay (`overlays/packages.nix`) also makes these available system-wide via `pkgs.*`.

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

The build system auto-discovers hosts, architectures, and users via `lib.scanNixFiles`, `lib.listSubDir`, and `lib.packagesFromByName`. `lib.scanNixFiles` is backed by `haumea`: it loads every module in a directory and drops the directory's own `default.nix`, so a subdirectory that grows its own module is picked up without editing the scan.

## Flake Inputs

| Input                | Description                                  |
| -------------------- | -------------------------------------------- |
| `nixpkgs`            | NixOS unstable channel                       |
| `home-manager`       | User environment manager                     |
| `apple-fonts`        | SF Pro, SF Mono, New York                    |
| `catppuccin`         | Catppuccin theme suite                       |
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
