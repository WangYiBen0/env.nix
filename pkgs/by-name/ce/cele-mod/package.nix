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
  version = "1.2.2";

  src = fetchFromGitHub {
    owner = "std-microblock";
    repo = "CeleMod";
    rev = "v${finalAttrs.version}";
    hash = "sha256-Tj6yx1NJU5+ALUydvHytO3ivpTdSSmmQYgfJQ4m7LJk=";
  };

  # The Cargo.toml/Cargo.lock of the tauri workspace live in the repo root;
  # keep cargoRoot at "." so fetchCargoVendor finds the lockfile.
  cargoRoot = ".";
  buildAndTestSubdir = "src-tauri";
  cargoDepsName = "cele-mod";
  cargoHash = "sha256-xbEoLgpx0vQ0MO79KtVaGyxbg+bO7uTedqT6pmX4OGQ=";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    sourceRoot = "${finalAttrs.src.name}/src/celemod-ui";
    fetcherVersion = 4;
    hash = "sha256-425ZsZww7FCOhXvBiVzpbO8zFBQc3wzJkQNd2q/gmRc=";
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

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "CeleMod - An alternative mod manager for Celeste";
    homepage = "https://github.com/std-microblock/CeleMod";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "cele-mod";
  };
})
