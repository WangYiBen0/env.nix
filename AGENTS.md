# AGENTS.md

Guidance for AI agents and humans working in this repository. Read this before
editing; most mistakes here are convention violations that the CI catches late.

## What this repository is

`W1ngD1nga5ter`'s AIO NixOS + Home Manager configuration, exposed as a flake.
Everything is hand-written Nix; there is no generation tooling.

Entry point: `flake.nix` → `outputs = inputs: import ./outputs inputs;`.
`outputs/default.nix` assembles `packages`, `checks`, `devShells`, `formatter`,
`overlays`, `lib`, `nixosConfigurations` and `homeConfigurations`.

## Layout

```
flake.nix                  inputs only; every input is documented inline
outputs/                   flake outputs, one file per output
hosts/                     nixosConfigurations + homeConfigurations wiring
  default.nix              builds nixosConfigurations for every host dir
  x86_64-linux/<host>/     one directory per machine; livecd.nix is a host too
  x86_64-linux/<host>/home/<user>/standalone/   marks a standalone HM user
modules/
  common/                  options.nix (all machine.* options), overlays.nix, nix.nix
  nixos/                   one file per feature, gated on machine.modules.*.enable
  home/                    same shape for Home Manager
  home-standalone/         HM-only wrapper modules
  home-as-module/          HM-as-NixOS-module wrapper modules
profiles/                  presets that flip several machine.modules.* at once
pkgs/by-name/<shard>/<pkg>/package.nix    in-repo packages (nixpkgs by-name shape)
overlays/                  every .nix here is merged into one overlay
lib/                       scanNixFiles, packagesFromByName, string helpers
wallpapers/                shared assets referenced by modules
```

## Hard rules

- **Never push to `main`.** It is protected. Work on a branch and open a pull
  request; the bot workflows do the same.
- **One concern per commit**, imperative subject, conventional prefix
  (`feat(scope):`, `fix(scope):`, `chore(scope):`, `ci:`, `docs:`).
  The automated update run is the exception: it always produces exactly
  `chore: update flake.lock, <pkgs>`.
- **All `machine.*` options live in `modules/common/options.nix`.** A module may
  declare its own sub-options under `machine.modules.<name>.*`, but the enable
  toggle is always `machine.modules.<name>.enable`, declared once in
  `options.nix`.
- **Every module is inert unless enabled.** Files under `modules/nixos/` and
  `modules/home/` are auto-imported by `lib.scanNixFiles`; a module that
  configures something unconditionally will affect every host.
- **Do not re-format unrelated files.** `nix fmt` and the pre-commit hooks are
  enforced, but a diff that reformats unrelated files will be rejected in
  review.
- **Comments explain why, not what.** The existing modules carry long comments
  about the failure that motivated a workaround; keep that style and never drop
  an existing rationale when editing nearby code.

## Adding a package

1. Create `pkgs/by-name/<two-letter-shard>/<name>/package.nix` (shard =
   lowercase prefix of the name; `ac` for `accesser`, `do` for `doona`).
2. Take `{ lib, stdenv, ..., nix-update-script }` as arguments; no `callPackage`
   boilerplate, the tree is imported by `lib.packagesFromByName`.
3. Add `passthru.updateScript = nix-update-script { };` — the update bot only
   manages packages defined in this flake.
4. Set `meta = { description; homepage; license; mainProgram; platforms; }`.
   `platforms` is load-bearing: `outputs/packages.nix` filters Darwin with
   `lib.meta.availableOn`, so a wrong value hides the package on one platform.
5. Supporting files (lockfiles, patches) go next to `package.nix`; nothing is
   installed from that directory automatically.

Non-trivial packages carry a header comment stating the upstream packaging
contract (how the artifact is laid out, which hashes exist, which upstream
script is reproduced and why).

## Adding a module

1. `modules/common/options.nix`: add
   `machine.modules.<name>.enable = lib.mkEnableOption "<one line>";`.
2. `modules/nixos/<name>.nix` and/or `modules/home/<name>.nix`, each shaped
   `{ config, lib, pkgs, ... }: lib.mkIf cfg.enable { ... }` with
   `cfg = config.machine.modules.<name>;`.
3. Document it in `modules/README.md` (table row + a `#### <name>` section for
   anything with options).
4. If a profile should enable it, add it to `profiles/desktop.nix` (or
   `server.nix`), not to a host.

## Verification before you call it done

```bash
nix flake check --no-build        # evaluates every output, ~2-4 min
nix build .#checks.x86_64-linux.pre-commit   # deadnix, nixfmt, prettier, statix, typos
nix build .#<package>             # builds it for real
```

`nix flake check` only _evaluates_. A package with a broken `installPhase`
passes it. Always build what you touched.

Test a NixOS module change by extending a real host instead of hand-rolling a
module system:

```bash
nix eval --impure --json --expr '
  let f = builtins.getFlake (toString ./.);
  in (f.nixosConfigurations.sxyz-19).extendModules {
    modules = [ { machine.modules.<name>.enable = true; } ];
  }.config.systemd.services.<name>.serviceConfig'
```

## CI

`.github/workflows/ci.yml` — required check `checks` runs `nix flake check`
and pushes built packages to Cachix on `main`.
`.github/workflows/closures.yml` — builds full system/home closures; only on
`main` or with the `build-closures` label.
`.github/workflows/update-pkgs.yml` — daily bot run: bumps `flake.lock`, runs
`nix-update` over every in-repo package, repairs fetch hashes, opens one PR and
enables auto-merge.

### update-pkgs quirks (read before touching the workflow)

- **Nothing is committed until the pull-request step.** That step resets to the
  run's base commit and commits everything as one `chore: update ...` commit,
  which also becomes the PR title. Do not add intermediate `git commit` calls:
  committing rewrites the git tree and re-keys the flake source mid-run.
- **Change detection is per package directory**, because nothing is committed
  between packages. A tree-wide `git diff` would flag every package after the
  first.
- **`nix-update` is patched** by `overlays/nix-update.nix` +
  `overlays/nix-update-lazy-source.patch` and exposed as `.#nix-update`
  (see `outputs/packages.nix`). Nix ≥ 2.35 no longer materialises the flake
  source path that `nix flake metadata --json` reports, so every post-rewrite
  eval failed with `opening file ...-source: No such file or directory`. The
  patch makes `nix-update` fall back to the working tree. The workflow resolves
  `.#nix-update`, never `nixpkgs#nix-update` — otherwise the nested
  `nix-update` inside a package's `updateScript` runs unpatched.
- **A package whose update script breaks fails the run on purpose**, at that
  package, so the PR is never opened on a tree known to be bad.
- **Packages must not rely on being committed** during the run: the run works
  on a dirty tree the whole time.

If a bot run fails, read which package aborted it, reproduce with
`nix-update --flake <pkg> --override-filename <file> --use-update-script` on a
clean tree, and fix the package (or its update script), not the workflow.

## Known traps

- **`lib.scanNixFiles` does not recurse.** A directory without `default.nix` is
  data, not modules. Files starting with `_` are private. A directory may not
  share its name with a sibling `.nix` file.
- **`nixpkgs#nix-update` is the unpatched build.** Use `.#nix-update`.
- **`doCheck = false` also disables `doInstallCheck`** on Python packages
  (`mk-python-derivation.nix` derives `doInstallCheck` from `doCheck`), so an
  `installCheckPhase` silently stops running.
- **Store paths are read-only.** Home Manager writes its config as store
  symlinks; anything that must change at runtime has to be copied to a real
  file in `$HOME` (see the Kvantum branch of the darkman script in
  `modules/home/theme.nix`: it rewrites `Kvantum/kvantum.kvconfig` beside the
  symlink instead of through it).
- **GTK resolves relative `url()` against the symlink's directory.** A
  `gtk-4.0/gtk.css` that `@import`s `assets/foo.css` works from the store but
  breaks once Home Manager links it into `~/.config/gtk-4.0`. Use absolute
  `file://` URLs (see `pkgs/by-name/wh/whitesur-libadwaita/package.nix`).
- **`nix flake metadata --json`'s `path` may not exist.** Do not pass it to
  `builtins.getFlake` without checking; evaluate the directory instead.
- **`unfree` is allowed** (`allowUnfree = true` in `outputs/default.nix` and
  `NIXPKGS_ALLOW_UNFREE=1` in CI), but a new unfree package still needs the
  licence in `meta`.
