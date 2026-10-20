{
  lib,
  stdenv,
  fetchurl,
  rustPlatform,
  bpf-linker,
  clang,
  cmake,
  git,
  jq,
  linkFarm,
  llvmPackages,
  llvmPackages_23,
  pkg-config,
  writeShellScript,
  zlib,
}:

let
  # Upstream has not tagged the native-API work yet; the doona-facing
  # release train pins a commit of the `native-api` branch, dated to
  # match upstream's own `debug.2026.10.4` build id.
  rev = "aebc0d78d567cac1cd74ee9c56674857c5441451";
  commitDate = "2026-10-20";

  # crates/honk-ebpf pins nightly-2026-07-20 for rustup users, but that
  # nightly's toolchain tarballs have since been removed from every
  # distribution channel (only its rust-src survives). Build the eBPF
  # object with the newest nightly still published, and patch the pin so
  # honk-core's build.rs freshness marker stays consistent.
  #
  # The pinned nightly emits LLVM 23 objects, so bpf-linker must be built
  # against LLVM 23 rather than nixpkgs' default LLVM.
  nightlyChannel = "nightly-2026-10-09";
  nightlyDate = "2026-10-09";

  # Artifact names are taken verbatim from the channel manifest of that date.
  rustNightly = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-nightly-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-kaYIudnKMACCTBnmABVvSuQ5dTefiaQi6sLUqCuIhkM=";
  };
  rustNightlySrc = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-src-nightly.tar.xz";
    hash = "sha256-IGNnushCGNzyuuTS9RDMRbR1BSCM7uwo3isFUNfOXes=";
  };

  bpfLinker = bpf-linker.override { llvmPackagesForLinker = llvmPackages_23; };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "honk";
  version = "0-unstable-${commitDate}";

  src = fetchurl {
    url = "https://github.com/Glassyiris/honk/archive/${rev}.tar.gz";
    hash = "sha256-dP9gZBXuOvKg4T2irKFzNe4hBCyBr9u07AbjX/BHuBc=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    # [patch.crates-io] pins three Glassyiris forks. The quinn trio share
    # one commit, hence one hash.
    outputHashes = {
      "boring-sys-5.2.0" = "sha256-VG0POjZdA2JazFt1jFe4UfdO01Pw7E1EC/7u8fOmfBs=";
      "quinn-0.11.12" = "sha256-UIv8chgSqA94r9u+r89z2DsLvdjPJoVJ9llIKvrrX90=";
      "quinn-proto-0.11.19" = "sha256-UIv8chgSqA94r9u+r89z2DsLvdjPJoVJ9llIKvrrX90=";
      "quinn-udp-0.5.16" = "sha256-UIv8chgSqA94r9u+r89z2DsLvdjPJoVJ9llIKvrrX90=";
    };
  };

  # honk-ebpf is excluded from the workspace and carries its own lockfile
  # (registry-only dependencies, so no outputHashes needed).
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

  # The eBPF object cannot come from honk-core's build.rs: that script
  # spawns a nested `cargo +<channel>` build, which presumes rustup. Build
  # the object up front with the pinned nightly and hand it to build.rs
  # through its documented fallback path `target/honk-core.o` plus the
  # `honk-core.toolchain` freshness marker.
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
      # The installers carry a /usr/bin/env shebang, which the sandbox
      # lacks; invoke them through stdenv's shell explicitly.
      bash rust-nightly-*/install.sh --prefix="$toolchain" \
        --components=rustc,cargo,rust-std-x86_64-unknown-linux-gnu \
        --disable-ldconfig
      (cd rust-src-nightly* && bash ./install.sh --prefix="$toolchain" --disable-ldconfig)

      # The rustup tarballs link against /lib64/ld-linux, absent in the
      # sandbox; retarget the interpreter at stdenv's loader and give the
      # bundled librustc_driver / libLLVM an rpath that covers libz.
      toolchainRpath="\$ORIGIN:$toolchain/lib:${lib.makeLibraryPath [ zlib ]}"
      while IFS= read -r -d $'\0' f; do
        [ "$(head -c 4 "$f")" = $'\x7fELF' ] || continue
        if patchelf --print-interpreter "$f" >/dev/null 2>&1; then
          patchelf --set-interpreter "$(cat "$NIX_CC"/nix-support/dynamic-linker)" \
            --set-rpath "$toolchainRpath" "$f"
        else
          patchelf --set-rpath "$toolchainRpath" "$f"
        fi
      done < <(find "$toolchain" -type f -print0)

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

    nativeBuildInputs = [ bpfLinker ];

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

  # Must be `buildFeatures`, not `cargoBuildFeatures`. buildRustPackage
  # accepts `buildFeatures` as an argument and re-exports it as
  # `cargoBuildFeatures` internally, so setting `cargoBuildFeatures` here
  # is silently shadowed by that re-export and cargo builds with an empty
  # feature set — honk-core then drops the native-api control plane (and
  # real eBPF) at runtime.
  buildFeatures = [
    "ebpf"
    "native-api"
  ];

  postPatch = ''
    substituteInPlace crates/honk-ebpf/rust-toolchain.toml \
      --replace-fail 'channel = "nightly-2026-07-20"' \
      'channel = "${nightlyChannel}"'
  '';

  preBuild = ''
    mkdir -p target
    install -Dm644 ${finalAttrs.ebpfObject}/honk-ebpf target/honk-core.o
    # build.rs validates the prebuilt object via `obj.with_extension("toolchain")`,
    # which REPLACES the .o extension — so the marker must be
    # `honk-core.toolchain`, not `honk-core.o.toolchain`. On a mismatch it
    # concludes the object is stale and shells out to `cargo +<nightly>` to
    # rebuild it, which cannot work in the sandbox (no rustup). The touch
    # also keeps the object newer than the sources so mtime staleness passes.
    printf '%s' "${nightlyChannel}" > target/honk-core.toolchain
    touch target/honk-core.o target/honk-core.toolchain
  '';

  # Upstream tests expect network access and a live kernel.
  doCheck = false;

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/honk-core" --version
    "$out/bin/honk-tool" --version
    runHook postInstallCheck
  '';

  passthru.updateScript = writeShellScript "update-honk" ''
    set -euo pipefail
    export PATH="${lib.makeBinPath [ jq ]}:$PATH"

    # The doona-facing native-api work lives on the Glassyiris fork's
    # feat/native-api branch (Zakkaus — doona's author — contributes there;
    # daeuniverse deleted their own native-api branch without merging it).
    # Walk its head by hand; nix-update cannot follow an untagged branch.
    # GH_TOKEN dodges the shared-runner IP rate limit.
    tmp=$(mktemp)
    code=$(curl -sS -o "$tmp" -w '%{http_code}' \
      ''${GH_TOKEN:+-H "Authorization: Bearer ''$GH_TOKEN"} \
      https://api.github.com/repos/Glassyiris/honk/commits/feat/native-api)
    if [ "$code" = 404 ] || [ "$code" = 422 ]; then
      echo "honk: feat/native-api is gone from the Glassyiris fork; skipping auto-update" >&2
      exit 0
    fi
    [ "$code" = 200 ] || { echo "error: GitHub API returned HTTP $code" >&2; exit 1; }
    rev=$(jq -r .sha "$tmp")
    date=$(jq -r .commit.author.date "$tmp" | cut -dT -f1)

    expr=pkgs/by-name/ho/honk/package.nix
    [ -f "$expr" ] || { echo "run this from the flake root" >&2; exit 1; }

    sed -i \
      -e "s|rev = \"[0-9a-f]\{40\}\"|rev = \"$rev\"|" \
      -e "s|commitDate = \"[0-9-]*\"|commitDate = \"$date\"|" \
      "$expr"

    # Refresh the src archive hash and the pinned Cargo.locks from the new
    # source, then repair the importCargoLock outputHashes through the
    # build-error loop so the update lands build-verified.
    src="https://github.com/Glassyiris/honk/archive/$rev.tar.gz"
    prefetch=$(nix store prefetch-file --json "$src")
    sri=$(echo "$prefetch" | jq -r .hash)
    storepath=$(echo "$prefetch" | jq -r .storePath)
    srcdir=$(mktemp -d)
    tar -xzf "$storepath" -C "$srcdir"
    treedir=$(echo "$srcdir"/honk-*)

    cp "$treedir/Cargo.lock" pkgs/by-name/ho/honk/Cargo.lock
    cp "$treedir/crates/honk-ebpf/Cargo.lock" pkgs/by-name/ho/honk/ebpf-Cargo.lock

    # The src hash sits on the line after the archive URL. Flag-based
    # matching — a getline here would swallow the URL line into $0. The
    # old value must never be part of the pattern: base64 hashes may
    # contain `/`, which terminates the awk regex literal early.
    inurl=0
    awk -v sri="$sri" '
      /Glassyiris\/honk\/archive\// { inurl = 1; print; next }
      inurl == 1 && /hash =/ { sub(/hash = "[^"]*"/, "hash = \"" sri "\""); inurl = 0; print; next }
      inurl == 1 { inurl = 0 }
      { print }
    ' "$expr" > "$expr.tmp"
    mv "$expr.tmp" "$expr"

    # importCargoLock outputHashes cannot be computed outside a build;
    # repair them from the hash-mismatch errors instead.
    err=$(mktemp)
    for i in $(seq 1 8); do
      if nix build --no-link ".#packages.x86_64-linux.honk" 2>"$err"; then
        echo ">> honk builds against $rev"
        rm -rf "$srcdir" "$err" "$tmp"
        exit 0
      fi
      specified=$(awk '/^[[:space:]]*specified:/{print $2; exit}' "$err")
      got=$(awk '/^[[:space:]]*got:/{print $2; exit}' "$err")
      if [ -z "$specified" ] || [ -z "$got" ]; then
        echo "error: nix build failed without a hash mismatch:" >&2
        cat "$err" >&2
        rm -rf "$srcdir" "$err" "$tmp"
        exit 1
      fi
      echo ">> repairing $specified -> $got"
      sed -i "s|$specified|$got|" "$expr"
    done
    echo "error: hash mismatches did not settle after 8 repair rounds:" >&2
    cat "$err" >&2
    rm -rf "$srcdir" "$err" "$tmp"
    exit 1
  '';

  meta = {
    description = "eBPF transparent proxy core that powers the doona UI";
    homepage = "https://github.com/daeuniverse/honk";
    changelog = "https://github.com/Glassyiris/honk/commits/feat/native-api";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "honk-core";
  };
})
