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
  # honk is developed on the `main` branch of daeuniverse/honk and is not
  # tagged there (the newest tag is v0.1.0-beta.6), so the revision is pinned
  # directly.  The doona-facing native API work that used to live on
  # Glassyiris/honk's feat/native-api branch has been merged into main.
  rev = "7cd8b13cd2b71081bd9c554b80a6a0e9a0dbdc04";
  commitDate = "2026-11-22";

  # crates/honk-ebpf pins the nightly that compiles the eBPF object.  The
  # pin is honoured as-is instead of being rewritten to "whatever nightly is
  # still downloadable": the channel string is also what honk-core's
  # build.rs compares against the freshness marker of a prebuilt object, so
  # a rewritten pin would need the marker rewritten with it.
  nightlyChannel = "nightly-2026-10-20";
  nightlyDate = "2026-10-20";

  # Artifact names are taken verbatim from the channel manifest of that date.
  rustNightly = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-nightly-x86_64-unknown-linux-gnu.tar.xz";
    hash = "sha256-BohyGBMzHsk2bkUhjR6frsgeFTa7zR0NbSKgGrJTIDg=";
  };
  rustNightlySrc = fetchurl {
    url = "https://static.rust-lang.org/dist/${nightlyDate}/rust-src-nightly.tar.xz";
    hash = "sha256-Ie8iCu/xBqHdEdkExpPY9ZZrepTbs2lfUjmr4naxJeI=";
  };

  # The pinned nightly emits LLVM 23 objects, so bpf-linker has to be built
  # against LLVM 23 rather than nixpkgs' default LLVM.  nixpkgs' rustc 1.99
  # already ships LLVM 23, so this override only pins the choice.
  bpfLinker = bpf-linker.override { llvmPackagesForLinker = llvmPackages_23; };

  # jq and git are only needed by the update script below; keeping the path
  # in a let-binding stops nixfmt from reflowing the interpolation.
  updatePath = lib.makeBinPath [
    jq
    git
  ];
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "honk";
  version = "0.1.0-unstable-${commitDate}";

  src = fetchurl {
    url = "https://github.com/daeuniverse/honk/archive/${rev}.tar.gz";
    hash = "sha256-VEnCTcJUchM5rGoFV/aF2u4IZ6B7qwnsAbvc/AvfBeY=";
  };

  cargoDeps = rustPlatform.importCargoLock {
    lockFile = ./Cargo.lock;
    # [patch.crates-io] pins three Glassyiris forks. The quinn trio share
    # one commit, hence one hash.
    outputHashes = {
      "boring-sys-5.2.0" = "sha256-VG0POjZdA2JazFt1jFe4UfdO01Pw7E1EC/7u8fOmfBs=";
      "quinn-0.11.12" = "sha256-N3oMkQ+bL0TeObMv5kdODEz8jfQr4wAODKEWqx8aCNI=";
      "quinn-proto-0.11.19" = "sha256-N3oMkQ+bL0TeObMv5kdODEz8jfQr4wAODKEWqx8aCNI=";
      "quinn-udp-0.5.16" = "sha256-N3oMkQ+bL0TeObMv5kdODEz8jfQr4wAODKEWqx8aCNI=";
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
  # spawns a nested `cargo +${channel}` build, which presumes rustup. Build
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

  # The workspace root is a virtual manifest, so a bare feature name does not
  # resolve; the features have to be qualified with the package that owns
  # them.  `ebpf` pulls in the real eBPF backend (and honk-nfqueue),
  # `native-api` the control plane the doona UI talks to.
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

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/honk-core" --version
    "$out/bin/honk-tool" --version
    runHook postInstallCheck
  '';

  passthru.updateScript = writeShellScript "update-honk" ''
    set -euo pipefail
    export PATH="${updatePath}:$PATH"

    # honk is developed on daeuniverse/honk's main branch, which is not
    # tagged; nix-update cannot follow an untagged branch, so walk its head
    # by hand.  git ls-remote needs no API token, unlike api.github.com.
    rev=$(git ls-remote https://github.com/daeuniverse/honk refs/heads/main | cut -f1)
    [ -n "$rev" ] || { echo "error: could not resolve daeuniverse/honk main" >&2; exit 1; }

    expr=pkgs/by-name/ho/honk/package.nix
    [ -f "$expr" ] || { echo "run this from the flake root" >&2; exit 1; }

    current=$(sed -n 's|^  rev = "\([0-9a-f]\{40\}\)";$|\1|p' "$expr" | head -1)
    if [ "$rev" = "$current" ]; then
      echo ">> honk is already at $rev"
      exit 0
    fi

    work=$(mktemp -d)
    trap 'rm -rf "$work"' EXIT

    # The commit date only names the build; a shallow clone is enough and
    # avoids the API's rate limit.
    git clone --quiet --depth 1 --filter=blob:none https://github.com/daeuniverse/honk "$work/honk"
    date=$(git -C "$work/honk" log -1 --format=%cs)

    # The eBPF crate pins the nightly that compiles the object; the pin and
    # the sysroot lockfile follow it.
    channel=$(sed -n 's|^channel = "\(.*\)"$|\1|p' "$work/honk/crates/honk-ebpf/rust-toolchain.toml" | head -1)
    nightlyDate=$(printf '%s' "$channel" | sed 's/^nightly-//')
    [ "$nightlyDate" != "$channel" ] || { echo "error: unexpected toolchain channel $channel" >&2; exit 1; }

    # Refresh the pinned Cargo.locks from the new source.
    cp "$work/honk/Cargo.lock" pkgs/by-name/ho/honk/Cargo.lock
    cp "$work/honk/crates/honk-ebpf/Cargo.lock" pkgs/by-name/ho/honk/ebpf-Cargo.lock

    # The sysroot lockfile is the nightly's own library/Cargo.lock.
    src_tarball="https://static.rust-lang.org/dist/$nightlyDate/rust-src-nightly.tar.xz"
    nix store prefetch-file --json "$src_tarball" > "$work/src.json"
    src_hash=$(jq -r .hash "$work/src.json")
    src_path=$(jq -r .storePath "$work/src.json")
    tar -xJf "$src_path" -C "$work" --wildcards \
      "rust-src-nightly/rust-src/lib/rustlib/src/rust/library/Cargo.lock"
    cp "$work/rust-src-nightly/rust-src/lib/rustlib/src/rust/library/Cargo.lock" \
      pkgs/by-name/ho/honk/sysroot-Cargo.lock

    nightly_tarball="https://static.rust-lang.org/dist/$nightlyDate/rust-nightly-x86_64-unknown-linux-gnu.tar.xz"
    nix store prefetch-file --json "$nightly_tarball" > "$work/nightly.json"
    nightly_hash=$(jq -r .hash "$work/nightly.json")

    # The src hash sits on the line after the archive URL. Flag-based
    # matching — a getline here would swallow the URL line into $0. The
    # old value must never be part of the pattern: base64 hashes may
    # contain `/`, which terminates the awk regex literal early.
    src_url="https://github.com/daeuniverse/honk/archive/$rev.tar.gz"
    nix store prefetch-file --json "$src_url" > "$work/src.json"
    src_hash=$(jq -r .hash "$work/src.json")

    # Everything the script rewrites lives above the update script itself.
    # From that line on the file is copied verbatim, so none of the patterns
    # below can match the awk program that follows them.
    #
    # Each hash sits on the line *after* its URL, so a pattern that spans
    # both cannot match; the URL therefore arms a flag and the next
    # "hash =" line is rewritten.  The old value must never be part of the
    # pattern: base64 hashes may contain "/", which terminates the awk
    # regex literal early.
    awk -v rev="$rev" -v date="$date" -v channel="$channel" -v nightlyDate="$nightlyDate" \
        -v nightlyHash="$nightly_hash" -v srcHash="$src_hash" '
      /passthru\.updateScript/ { copy = 1; print; next }
      copy == 1 { print; next }
      /^  rev = "/ { sub(/rev = "[0-9a-f]{40}"/, "rev = \"" rev "\""); print; next }
      /daeuniverse\/honk\/archive\// { inurl = 1; print; next }
      inurl == 1 && /hash =/ { sub(/hash = "[^"]*"/, "hash = \"" srcHash "\""); inurl = 0; print; next }
      inurl == 1 { inurl = 0 }
      /rust-nightly-x86_64-unknown-linux-gnu\.tar\.xz/ { want = "nightly"; print; next }
      /rust-src-nightly\.tar\.xz/ { want = "src"; print; next }
      want == "nightly" && /hash =/ { sub(/hash = "[^"]*"/, "hash = \"" nightlyHash "\""); want = ""; print; next }
      want == "src" && /hash =/ { sub(/hash = "[^"]*"/, "hash = \"" srcHash "\""); want = ""; print; next }
      want != "" { want = "" }
      /commitDate =/ { sub(/commitDate = "[0-9-]*"/, "commitDate = \"" date "\""); print; next }
      /nightlyChannel =/ { sub(/nightlyChannel = "[^"]*"/, "nightlyChannel = \"" channel "\""); print; next }
      /nightlyDate =/ { sub(/nightlyDate = "[^"]*"/, "nightlyDate = \"" nightlyDate "\""); print; next }
      { print }
    ' "$expr" > "$expr.tmp"
    mv "$expr.tmp" "$expr"

    # importCargoLock outputHashes cannot be computed outside a build;
    # repair them from the hash-mismatch errors instead.
    err=$(mktemp)
    for i in $(seq 1 8); do
      if nix build --no-link ".#packages.x86_64-linux.honk" 2>"$err"; then
        echo ">> honk builds against $rev"
        exit 0
      fi
      specified=$(awk '/^[[:space:]]*specified:/{print $2; exit}' "$err")
      got=$(awk '/^[[:space:]]*got:/{print $2; exit}' "$err")
      if [ -z "$specified" ] || [ -z "$got" ]; then
        echo "error: nix build failed without a hash mismatch:" >&2
        cat "$err" >&2
        exit 1
      fi
      echo ">> repairing $specified -> $got"
      sed -i "s|$specified|$got|" "$expr"
    done
    echo "error: hash mismatches did not settle after 8 repair rounds:" >&2
    cat "$err" >&2
    exit 1
  '';

  meta = {
    description = "eBPF transparent proxy core that powers the doona UI";
    homepage = "https://github.com/daeuniverse/honk";
    changelog = "https://github.com/daeuniverse/honk/commits/main";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "honk-core";
  };
})
