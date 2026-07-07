# env.nix

My all-in-one environment configuration, including NixOS & Home Manager.

## Quick Start

```bash
# Deploy everything (NixOS + Home Manager)
nh os switch .

# Debug Home Manager standalone
nh home switch -- --flake .#w1ngd1nga5ter@matebook16d
```

## Project Structure

```
.
├── flake.nix                 # Flake entry, defines inputs
├── outputs/                  # Flake outputs, deployment, dev tools
├── hosts/                    # Per-host NixOS + HM configs
├── modules/                  # Shared NixOS & HM modules
├── lib/                      # Custom lib (scanNixFiles, listSubDir)
├── overlays/                 # Package overlays
└── pkgs/                     # Custom packages (fonts)
```

## Documentation

| Directory                     | Docs                                         |
| ----------------------------- | -------------------------------------------- |
| [hosts/](hosts/README.md)     | Managed machines, host auto-discovery        |
| [modules/](modules/README.md) | Profile system, NixOS & HM modules           |
| [outputs/](outputs/README.md) | Deployment, flake outputs, dev tools, caches |

## License

Do what you want, just don't blame me if it breaks.
