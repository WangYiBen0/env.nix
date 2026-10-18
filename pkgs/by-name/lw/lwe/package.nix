{
  lib,
  rustPlatform,
  fetchFromGitHub,
  fetchPnpmDeps,
  nix-update-script,
  cargo-tauri,
  nodejs,
  pnpm,
  pnpmConfigHook,
  pkg-config,
  wrapGAppsHook3,
  glib-networking,
  gtk3,
  libayatana-appindicator,
  libGL,
  mpv-unwrapped,
  vulkan-loader,
  webkitgtk_4_1,
}:

# The Tauri CLI would invoke `pnpm run build` itself via
# `build.beforeBuildCommand`; override it and build the SvelteKit frontend
# in preBuild instead, so the frontend build runs in the repo root rather
# than in `buildAndTestSubdir`.
let
  tauriOverrides = builtins.toFile "tauri-overrides.json" (
    builtins.toJSON {
      build.beforeBuildCommand = "";
    }
  );
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "lwe";
  version = "0.9.11";

  src = fetchFromGitHub {
    owner = "YangYuS8";
    repo = "lwe";
    rev = "v${finalAttrs.version}";
    hash = "sha256-7slseQhrzt0wFExBZqYCGG2nA+nVHPZVaD1Xce4he64=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    fetcherVersion = 4;
    hash = "sha256-Rmhw9L0c/lgRAviymZoOGDXbK6cCkd6hm1JUl8MQYrM=";
  };

  # The Cargo workspace (and its lockfile) live in the repo root; the Tauri
  # shell crate is the src-tauri member.
  cargoRoot = ".";
  buildAndTestSubdir = "src-tauri";
  cargoHash = "sha256-brRtUyx+4eVjfgUBA5pfw+/ugTgjojQwpKNgHd4PEl4=";

  nativeBuildInputs = [
    cargo-tauri.hook
    pnpmConfigHook
    nodejs
    pnpm
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    glib-networking
    gtk3
    libayatana-appindicator
    libGL
    mpv-unwrapped
    vulkan-loader
    webkitgtk_4_1
  ];

  tauriBuildFlags = [
    "-c"
    tauriOverrides
  ];

  preBuild = ''
    pnpm run build
  '';

  # The test suite drives GUI/Wayland code paths.
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Linux desktop app for browsing, managing, and applying Wallpaper Engine content";
    homepage = "https://github.com/YangYuS8/lwe";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
    # Tauri v2's deb bundler keeps the crate's binary name (`lwe-shell`) for
    # the binary, desktop Exec and icon, so point mainProgram at that.
    mainProgram = "lwe-shell";
  };
})
