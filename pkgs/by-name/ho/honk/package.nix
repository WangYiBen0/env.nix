{
  lib,
  stdenv,
  fetchurl,
  rustPlatform,
  bpf-linker,
  clang,
  cmake,
  git,
  linkFarm,
  llvmPackages,
  nix-update-script,
  pkg-config,
  zlib,
}:

# Upstream packaging contract:
#   * daeuniverse/honk is a Cargo workspace. The workspace root is a virtual
#     manifest, so feature names must be qualified with the crate that owns
#     them: `honk-core/ebpf,honk-core/native-api` is the set the NixOS module
#     needs (real eBPF backend plus the control plane doona talks to).
#   * The eBPF object is a nested cross-build: crates/honk-ebpf pins its own
#     toolchain in rust-toolchain.toml (currently nightly-2026-10-20) because
#     it needs -Zbuild-std=core for bpfel-unknown-none. That toolchain is
#     honoured as-is instead of being swapped for nixpkgs' rustc: build.rs
#     compares the channel string against the prebuilt object's freshness
#     marker, so rewriting one without the other makes every build treat the
#     object as stale and shell out to rustup, which the sandbox does not have.
#   * Because the object cannot be produced by honk-core's build.rs, it is
#     built here first with that pinned nightly and handed over through the
#     documented fallback path (target/honk-core.o plus a .toolchain marker).
#   * doona is served from pkgs.doona by the NixOS module
#     (experimental.native_api.ui), so the `native-ui` feature — which would
#     embed a copy at build time from HONK_DOONA_DIR — is deliberately off.
let
  version = "0.1.0-beta.7";

  # crates/honk-ebpf pins the nightly that compiles the eBPF object; keep both
  # halves of the pin together.
  nightlyChannel = "nightly-2026-10-20";
  nightlyDate = "2026-10-20";

  rustNightly = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-nightly-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-BohyGBMzHsk2bkUhjR6frsgeFTa7zR0NbSKgGrJTIDg=";
  };
  rustNightlySrc = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-src-nightly.tar.xz";
    hash = "sha256-Ie8iCu/xBqHdEdkExpPY9ZZrepTbs2lfUjmr4naxJeI=";
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "honk";
  inherit version;

  src = fetchurl {
    url = "https://github.com/daeuniverse/honk/archive/v${finalAttrs.version}.tar.gz";
    hash = "sha256-CyYrICG43i8r9pNZ4RhMbY8nmlXz0HbMms/ZTQXxlOk=";
  };
  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    # [patch.crates-io] replaces four crates with Glassyiris forks: boring-sys
    # (the rprx/REALITY ClientHello hooks) and the quinn trio (receive
    # fragmentation bounds, BBRv3 pacing). The three quinn crates share one
    # repository commit, so they share one hash.
    outputHashes = {
      "boring-sys-5.2.0" = "sha256-VG0POjZdA2JazFt1jFe4UfdO01Pw7E1EC/7u8fOmfBs=";
      "quinn-0.11.12" = "sha256-86/NY/NkN5F2omHPusN/GddwhUDfYEX8SsTCqztLwr0=";
      "quinn-proto-0.11.19" = "sha256-86/NY/NkN5F2omHPusN/GddwhUDfYEX8SsTCqztLwr0=";
      "quinn-udp-0.5.16" = "sha256-86/NY/NkN5F2omHPusN/GddwhUDfYEX8SsTCqztLwr0=";
    };
  };

  # honk-ebpf is excluded from the workspace and carries its own lockfile
  # (registry-only dependencies, so no outputHashes).
  ebpfCargoDeps = rustPlatform.importCargoLock {
    lockFile = ./ebpf-Cargo.lock;
  };

  # -Zbuild-std also resolves the sysroot's own registry dependencies
  # (library/Cargo.lock ships inside the rust-src component); vendor them
  # alongside the crate's so the offline build can resolve both graphs.
  sysrootCargoDeps = rustPlatform.importCargoLock {
    lockFile = ./sysroot-Cargo.lock;
  };

  # Cargo accepts exactly one directory source, so merge the two vendors.
  mergedEbpfVendor = linkFarm "honk-ebpf-vendor" (
    lib.concatMap
      (
        dir:
        lib.mapAttrsToList (name: _: {
          inherit name;
          path = "${dir}/${name}";
        }) (builtins.readDir dir)
      )
      [
        finalAttrs.ebpfCargoDeps
        finalAttrs.sysrootCargoDeps
      ]
  );

  # The eBPF object cannot come from honk-core's build.rs: that script spawns
  # a nested `cargo +channel` build, which presumes rustup. Build the object up
  # front with the pinned nightly and hand it to build.rs through its
  # documented fallback path `target/honk-core.o` plus the `honk-core.toolchain`
  # freshness marker.
  ebpfObject = stdenv.mkDerivation {
    pname = "honk-ebpf-object";
    inherit (finalAttrs) version src;

    unpackPhase = ''
      runHook preUnpack
      unpackFile "$src"
      unpackFile ${rustNightly}
      unpackFile ${rustNightlySrc}
      mv honk-* source
      chmod -R +w source
      runHook postUnpack
    '';

    buildPhase = ''
      runHook preBuild

      toolchain="$PWD/toolchain"
      # The installers carry a /usr/bin/env shebang, which the sandbox lacks;
      # invoke them through stdenv's shell explicitly.
      bash rust-nightly-*/install.sh --prefix="$toolchain" \
        --components=rustc,cargo,rust-std-x86_64-unknown-linux-gnu \
        --disable-ldconfig
      (cd rust-src-nightly* && bash ./install.sh --prefix="$toolchain" --disable-ldconfig)

      # The rustup tarballs link against /lib64/ld-linux, absent in the
      # sandbox; retarget the interpreter at stdenv's loader and give the
      # bundled librustc_driver / libLLVM an rpath that covers libz.
      toolchainRpath="\$ORIGIN:$toolchain/lib:${lib.makeLibraryPath [ zlib ]}"
      # find runs the rewrite itself instead of piping into a while-read loop:
      # a NUL delimiter argument needs an empty quote literal, which is
      # awkward to keep intact inside a Nix indented string.
      find "$toolchain" -type f -exec sh -c '
        f="$1"
        [ "$(head -c 4 "$f")" = "$(printf "\\177ELF")" ] || exit 0
        if patchelf --print-interpreter "$f" >/dev/null 2>&1; then
          patchelf --set-interpreter "$2" --set-rpath "$3" "$f"
        else
          patchelf --set-rpath "$3" "$f"
        fi
      ' sh {} "$(cat "$NIX_CC"/nix-support/dynamic-linker)" "$toolchainRpath" \;

      export PATH="$toolchain/bin:$PATH"
      export CARGO_HOME="$PWD/cargo-home"
      mkdir -p "$CARGO_HOME"
      cat > "$CARGO_HOME/config.toml" <<EOF
      [source.crates-io]
      replace-with = "vendored-sources"
      [source.vendored-sources]
      directory = "${finalAttrs.mergedEbpfVendor}"
      EOF

      # The crate's own .cargo/config.toml supplies the BTF-generating
      # bpf-linker invocation; RUSTFLAGS is deliberately left untouched.
      cd source/crates/honk-ebpf
      cargo build --release --locked --offline \
        --target bpfel-unknown-none -Zbuild-std=core

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 target/bpfel-unknown-none/release/honk-ebpf "$out/honk-ebpf"
      runHook postInstall
    '';

    nativeBuildInputs = [ bpf-linker ];

    # Stripping would destroy the .BTF section build.rs verifies.
    dontStrip = true;
  };
  # cmake is here only so boring-sys's build script can drive BoringSSL;
  # the crate itself has no configure step, so skip stdenv's cmake phase.
  dontConfigure = true;

  nativeBuildInputs = [
    clang
    cmake
    # boring-sys's build script runs `git init` inside the vendored
    # BoringSSL tree to stamp a revision.
    git
    pkg-config
  ];

  # boring-sys runs bindgen against BoringSSL headers at build time.
  env.LIBCLANG_PATH = lib.makeLibraryPath [ llvmPackages.libclang.lib ];

  cargoBuildFlags = [
    "--features"
    "honk-core/ebpf,honk-core/native-api"
  ];

  preBuild = ''
    mkdir -p target
    install -Dm644 ${finalAttrs.ebpfObject}/honk-ebpf target/honk-core.o
    # build.rs validates the prebuilt object via `obj.with_extension("toolchain")`,
    # which REPLACES the .o extension — so the marker must be
    # `honk-core.toolchain`, not `honk-core.o.toolchain`. On a mismatch it
    # concludes the object is stale and shells out to `cargo +${nightlyChannel}`
    # to rebuild it, which cannot work in the sandbox (no rustup). The touch
    # also keeps the object newer than the sources so mtime staleness passes.
    printf '%s' "${nightlyChannel}" > target/honk-core.toolchain
    touch target/honk-core.o target/honk-core.toolchain
  '';

  # Upstream tests expect network access and a live kernel.
  doCheck = false;

  # honk-tool is a diagnostics CLI (subscription checks, pinned-map reads,
  # geo data search) that nobody runs from a boot path, and it is 20 MB of the
  # 58 MB tree. Splitting it into its own output keeps the daemon closure and
  # the installed system closure from carrying it: `cfg.package` in the NixOS
  # module resolves to `out`, so `tool` is only built when something names it.
  # It saves disk, not dependencies — both binaries reference exactly the same
  # store paths.
  outputs = [
    "out"
    "tool"
  ];

  postInstall = ''
    moveToOutput "bin/honk-tool" "$tool"
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/honk-core" --version
    "$tool/bin/honk-tool" --version
    runHook postInstallCheck
  '';

  # Upstream tags every release, so the generic release-feed path works; the
  # flags are the same two the package needed when it consumed release assets.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      # releases.atom also lists rolling debug tags, which sort above every
      # v0.1.0-beta.N because a numeric segment outranks an alpha one.
      "--version-regex"
      "v?([0-9.]+(?:-[a-z]+\\.[0-9.]+)*)"
      # Every published tag so far is a pre-release.
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "eBPF transparent proxy engine with the doona native API";
    homepage = "https://github.com/daeuniverse/honk";
    changelog = "https://github.com/daeuniverse/honk/releases";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "honk-core";
  };
})
