# Profiles

High-level presets that set multiple `machine.*` options at once. A profile
only flips options — every NixOS- or Home-Manager-specific implementation
lives behind its own enable option in [`modules/`](../modules/README.md).

Profiles are imported wherever `modules/` is (NixOS hosts, Home Manager as a
NixOS module, standalone Home Manager), so a profile may only reference
`machine.*` options, which exist in every context. There is intentionally no
nixos/home split here.

Enable one in the host's `default.nix` (NixOS side) or the user's
`home/<user>/default.nix` (Home Manager side):

```nix
machine.profiles.desktop = true;  # full desktop machine
machine.profiles.server = true;   # (reserved for future use)
```

## Directory Structure

```
profiles/
├── default.nix     # Auto-imports all .nix via scanNixFiles
├── desktop.nix     # Full desktop stack (gated: machine.profiles.desktop)
└── server.nix      # (reserved)
```
