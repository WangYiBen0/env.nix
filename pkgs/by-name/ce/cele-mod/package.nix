{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  cargo-tauri,
  nix-update-script,
  nodejs,
  pnpm,
  pnpmConfigHook,
  pkg-config,
  cmake,
  glib-networking,
  openssl,
  webkitgtk_4_1,
  wrapGAppsHook4,
}:

# Disable the frontend build that `cargo tauri build` would trigger via
# `beforeBuildCommand`; the UI is built beforehand in src/celemod-ui.
let
  tauriOverrides = builtins.toFile "tauri-overrides.json" (
    builtins.toJSON {
      build.beforeBuildCommand = "";
    }
  );
in

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "cele-mod";
  version = "1.2.1";

  src = fetchFromGitHub {
    owner = "std-microblock";
    repo = "CeleMod";
    rev = "v${finalAttrs.version}";
    hash = "sha256-A3LWCZdd7z2ylrrcCKl0/AWi++XVg4mZVBVJK/EEuK0=";
  };

  # The Cargo.toml/Cargo.lock of the tauri workspace live in the repo root;
  # keep cargoRoot at "." so fetchCargoVendor finds the lockfile.
  cargoRoot = ".";
  buildAndTestSubdir = "src-tauri";
  cargoDepsName = "cele-mod";
  cargoHash = "sha256-0cDrRKfRl6gVs7nkizottGRQyyXnkH5MKZlH0DhmgKI=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    sourceRoot = "${finalAttrs.src.name}/src/celemod-ui";
    fetcherVersion = 4;
    hash = "sha256-fGsindZv1KOLPD4zCh42++RiXgA3jmsUBWbq++0YNZw=";
  };

  pnpmRoot = "src/celemod-ui";

  nativeBuildInputs = [
    cargo-tauri.hook
    pnpmConfigHook
    nodejs
    pnpm
    pkg-config
    cmake
    wrapGAppsHook4
  ];

  buildInputs = [
    glib-networking
    openssl
    webkitgtk_4_1
  ];

  tauriBuildFlags = [
    "-c"
    tauriOverrides
  ];

  preBuild = ''
    pnpm --dir src/celemod-ui build
  '';

  # The cargo tests drive the tauri GUI.
  doCheck = false;

  env = {
    CMAKE_POLICY_VERSION_MINIMUM = "3.5";
    # The crate relies on the nightly-only `try_blocks` feature
    # (see .rust-toolchain.toml / src-tauri/src/lib.rs).
    RUSTC_BOOTSTRAP = "1";
  };

  passthru.updateScript = nix-update-script {
    # The update script re-invokes nix-update without --flake, which cannot
    # eval this flake; always point it back at the local flake.
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "CeleMod - An alternative mod manager for Celeste";
    homepage = "https://github.com/std-microblock/CeleMod";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cele-mod";
  };
})
