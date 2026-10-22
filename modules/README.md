# Modules

## Module System

The module system uses two layers:

1. **Profiles** — high-level presets that set multiple module options at once.
   They live in [`profiles/`](../profiles/README.md) at the project root and
   only flip `machine.*` options.
2. **Modules** — individual features with their own enable options. Every
   module here is gated behind a single enable option; importing a module
   alone enables nothing.

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

Directories are imported by `lib.scanNixFiles`, which loads every `.nix` file through `haumea` and keeps the directory's own `default.nix` out of the result. Two consequences: a directory may not share its name with a sibling file (both would map to the same attribute), and `_`-prefixed files stay private instead of being imported as modules.

## What Each Module Enables

### NixOS Modules

| Module       | Option                                | Description                                                       |
| ------------ | ------------------------------------- | ----------------------------------------------------------------- |
| desktop      | `machine.modules.desktop.enable`      | Desktop session: plasma + niri, desktop apps, firewall exceptions |
| font         | `machine.modules.font.enable`         | System fonts (Noto, Maple Mono, JetBrains Mono, …)                |
| compat       | `machine.modules.compat.enable`       | nix-ld, flatpak, podman, Wine                                     |
| honk         | `machine.modules.honk.enable`         | honk transparent proxy + doona web UI                             |
| system       | `machine.modules.system.enable`       | Base system: kernel, timezone, locale, boot                       |
| services     | `machine.modules.services.enable`     | Base services: PipeWire, SSH, bluetooth, printing                 |
| packages     | `machine.modules.packages.enable`     | System packages (shared with the HM side)                         |
| nix          | `machine.modules.nix.enable`          | Nix settings, caches, GC (shared with common/ and HM)             |
| nixpak       | `machine.modules.nixpak.enable`       | Bubblewrap sandbox for closed-source apps (dingtalk)              |
| impermanence | `machine.modules.impermanence.enable` | Bind-mounts state from `/persist` (preservation)                  |

#### honk options

| Option             | Default              | Description                                                              |
| ------------------ | -------------------- | ------------------------------------------------------------------------ |
| `settings`         | direct-only fallback | honk's base config in dae syntax, installed to `/var/lib/honk/base.dae`  |
| `api.listen`       | `127.0.0.1:9527`     | Native API and doona UI bind address                                     |
| `api.port`         | `9527`               | Port opened in the firewall                                              |
| `api.passwordAuth` | `true`               | Sign in with an administrator account (mutually exclusive with `secret`) |
| `api.secret`       | `null`               | API token instead of password login                                      |
| `api.configWrite`  | `true`               | Let the UI edit nodes, subscriptions and rules                           |

The `experimental.native_api` block is appended to the main config from the
`api.*` options; honk serves doona from the package's `share/doona` at `/ui/`.
honk resolves `include` against the canonical path of its config file, which
breaks for NixOS's `/nix/store` symlinks, so everything lives in one file.
honk reads its config once at startup, so the file is embedded in the unit as
a restart trigger — `nixos-rebuild switch` restarts honk whenever it changes.
`settings` also pins `global.nfqueue_enable: false`; when NFQUEUE is
unavailable honk downgrades the key in the running config but not in the file,
and that restart-required drift makes every managed config write (adding a
subscription in the UI, saving) fail with 422 "Configuration validation failed".

honk needs Linux 6.12+, a bpffs mount at `/sys/fs/bpf`, and runs as root.
Reach the UI from another machine by setting `api.listen` to a LAN address.

#### nixpak

`machine.modules.nixpak.enable` takes `dingtalk` out of
`environment.systemPackages` and installs a [nixpak](https://github.com/nixpak/nixpak)
wrapper instead: the same application behind bubblewrap, with a private
`$HOME` under `~/.local/share/nixpak/`, no access to the real home directory,
and only the D-Bus surface a desktop app needs (notifications, portals, the
fcitx IME, the status notifier). `~/Downloads` stays writable so received files
land where the user expects them.

The wrapper keeps the package name, so launchers and `xdg-open` still find it.
The sandbox home starts empty, so the first launch looks like a fresh install,
and anything the app would store elsewhere in the real home stays invisible to
it.

QQ is deliberately not sandboxed: `pkgs.linuxqq` is Tencent's own
Wayland-optimised build and already talks to the compositor, the IME and the
portal correctly, so interposing bubblewrap only puts a layer between the app
and plumbing that works.

Everything the sandboxes are allowed to touch lives in `desktopSandbox` in
[`nixos/nixpak.nix`](nixos/nixpak.nix) — that is the list to widen if an app
turns out to need another D-Bus name (tray icon, clipboard), another socket, or
another directory. The launcher also needs a Go build the first time; it is
fetched from `proxy.golang.org`, so a network that blocks it needs `GOPROXY`
pointed elsewhere.

#### impermanence

`machine.modules.impermanence.enable` turns the state list in
[`nixos/preservation.nix`](nixos/preservation.nix) into bind mounts from
`/persist`, using [preservation](https://github.com/nix-community/preservation).
Off by default and inert while off: `/` is still a persistent subvolume, so this
is prep work for making the root ephemeral later. `/home` is its own subvolume,
so user data is deliberately not in the list.

The mount is declared in the host's `disko.nix` (that is also what creates the
subvolume on a fresh install), and the module asserts it exists instead of
guessing — a missing `/persist` would let the bind mounts read from the
ephemeral root and the state would silently land in the wrong place.
`sxyz-89` is the host with it switched on, which means an **existing** system
needs the subvolume created once before the first switch:

```bash
dev=$(findmnt -no SOURCE /)                # the btrfs root, whatever its name
sudo mount -o subvol=/ "$dev" /mnt
sudo btrfs subvolume create /mnt/nixos/@persist   # `@persist` on hosts without the nixos/ prefix
sudo umount /mnt

# seed it with the state that already exists, otherwise the first boot starts empty
sudo mount -o subvol=nixos/@persist "$dev" /persist
sudo mkdir -p /persist/var/lib /persist/etc/ssh
sudo rsync --archive --hard-links --acls --xattrs /var/lib/{nixos,NetworkManager,bluetooth,flatpak,containers,docker,honk} /persist/var/lib/
sudo cp -a /etc/ssh/ssh_host_* /persist/etc/ssh/
sudo umount /persist
```

The live CD below boots into a system with the tools for exactly this job.

### Home Manager Modules

| Module           | Option                                    | Description                                          |
| ---------------- | ----------------------------------------- | ---------------------------------------------------- |
| desktop          | `machine.modules.desktop.enable`          | Desktop user apps, zen-browser, swaync, polkit agent |
| packages         | `machine.modules.packages.enable`         | User CLI packages (shared with the NixOS side)       |
| nix              | `machine.modules.nix.enable`              | home-manager self-management (shared)                |
| shell            | `machine.modules.shell.enable`            | Bash, Fish, Bat, Eza, Zellij, Zoxide, aliases        |
| starship         | `machine.modules.starship.enable`         | Starship prompt                                      |
| git              | `machine.modules.git.enable`              | Git identity and settings                            |
| editor           | `machine.modules.editor.enable`           | Nixvim                                               |
| yazi             | `machine.modules.yazi.enable`             | Yazi file manager + plugins                          |
| nix-index        | `machine.modules.nix-index.enable`        | nix-index + comma                                    |
| niri             | `machine.modules.niri.enable`             | Niri compositor config                               |
| kitty            | `machine.modules.kitty.enable`            | Kitty terminal                                       |
| font             | `machine.modules.font.enable`             | User fonts + fontconfig                              |
| ime              | `machine.modules.ime.enable`              | Fcitx5 + RIME + rime-ice                             |
| launcher         | `machine.modules.launcher.enable`         | Fuzzel launcher                                      |
| theme            | `machine.modules.theme.enable`            | Cursor, GTK, Qt, Catppuccin                          |
| directory        | `machine.modules.directory.enable`        | XDG user directories                                 |
| variable         | `machine.modules.variable.enable`         | Desktop session variables                            |
| deepseek-harness | `machine.modules.deepseek-harness.enable` | dsh web UI user service                              |

### Always-Loaded Modules

Only plumbing is always loaded: `common/options.nix` (all `machine.*`
declarations), `common/overlays.nix` (project overlays) and the external
module imports in `*/modules.nix`. Generic personal defaults (timezone,
locale, git identity, personal cachix) live inside gated modules and are
enabled by the desktop profile.

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
│   ├── honk.nix              # honk proxy + doona web UI (gated: machine.modules.honk.enable)
│   ├── nixpak.nix            # dingtalk sandbox (gated: machine.modules.nixpak.enable)
│   ├── preservation.nix      # /persist bind mounts (gated: machine.modules.impermanence.enable)
│   ├── compat.nix            # nix-ld, flatpak, podman, Wine (gated: machine.modules.compat.enable)
│   ├── font.nix              # System fonts (gated: machine.modules.font.enable)
│   └── desktop.nix           # Desktop session bundle (gated: machine.modules.desktop.enable)
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
│   ├── deepseek-harness.nix  # dsh web UI user service (gated: machine.modules.deepseek-harness.enable)
│   └── desktop.nix           # Desktop user apps + polkit agent (gated: machine.modules.desktop.enable)
├── home-standalone/          # Standalone Home Manager modules
└── home-as-module/           # Home Manager as NixOS module
```

## Loading Order

1. `modules/common/` — loaded first (options, overlays, shared packages)
2. `modules/nixos/` or `modules/home/` — loaded by host configs
3. `profiles/` (project root) — imported alongside them; a profile sets
   module options → modules check their enable options
4. Host-specific overrides — loaded last (highest priority)
