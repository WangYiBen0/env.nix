{
  lib,
  llvmPackages_22,
  fetchFromGitHub,
  runCommand,
  symlinkJoin,
  makeWrapper,
  git,
  curl,
  cargo,
  rustc,
  cmake,
  ninja,
  pkg-config,
  protobuf,
  glslang,
  lito,
  cacert,
  libpulseaudio,
  wayland,
  wayland-protocols,
  ffmpeg,
  libgbm,
  libva,
  freetype,
  expat,
  dav1d,
  lz4,
  vulkan-loader,
  vulkan-headers,
  libGL,
  libxkbcommon,
  qt6,
  nix-update-script,
}:

let
  version = "0.4.4";
  # tag v0.4.4; pinned as a full commit so fetchFromGitHub skips the
  # rate-limited GitHub tag-resolution API.
  rev = "f42cb1a6b12301dfd1b46e1ef1cfbce6140bc5d3";

  src = fetchFromGitHub {
    owner = "waywallen";
    repo = "waywallen";
    inherit rev;
    hash = "sha256-/ML7KKSes00fT/2fpRcAu0TjTSuSD2lMmXcOmOu4vpI=";
  };

  qt6Env = symlinkJoin {
    name = "qt6-unified-env";
    paths = with qt6; [
      qtbase
      qtdeclarative
      qtshadertools
      qtwebsockets
      qtgrpc
      qttools
    ];
  };

  # Runtime libs every waywallen binary dlopens/links at runtime.
  runtimeLibs = [
    vulkan-loader
    libGL
    wayland
    libgbm
    ffmpeg
    libpulseaudio
    libva
    qt6Env
  ];

  # Lito resolves dependencies from a registry and GitHub at build time, which
  # the sandbox forbids. This fixed-output derivation captures the portable
  # source bundle (Lito sources + the vendored Cargo tree + offline cargo
  # config) with `lito fetch`, then repairs the one layout detail cargo needs:
  # `cargo --config <bundle>/v1/cargo/<key>/config.toml` resolves its relative
  # `directory = "vendor"` against the *parent* of the config directory, so a
  # `v1/cargo/vendor` symlink makes the vendored sources visible offline.
  sourceBundle =
    runCommand "waywallen-lito-source-bundle-${version}"
      {
        nativeBuildInputs = [
          lito
          git
          curl
          cargo
          rustc
          # lito resolves its toolchain (clang++, llvm-ar, ld.lld) at startup
          # even for `fetch`.
          llvmPackages_22.clang
          llvmPackages_22.lld
          llvmPackages_22.llvm
          cmake
          ninja
          pkg-config
        ];
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        # Local check: nix hash path on a scratch `lito fetch --output` tree.
        outputHash = "sha256-Le7jqPDgZ/AHSPLqj4frhhvc1UkaMEw25RYMX9eX3YE=";

        env.LITO_ALLOWED_ROOTS = "/nix/store:/build";
        # stdenv pins SSL_CERT_FILE=/no-cert-file.crt inside fixed-output
        # derivations (anti-exfiltration measure). On NixOS the sandbox still
        # mounts the host CA bundle, but on vanilla nix (e.g. the GitHub
        # runners of the Update pkgs workflow) it does not, so TLS inside
        # this FOD dies with "unable to get local issuer certificate".
        # Exported inside the script below (after setup.sh's own pinning):
        # curl reads CURL_CA_BUNDLE, git reads GIT_SSL_CAINFO, and nixpkgs
        # libcurl honors NIX_SSL_CERT_FILE.
        env.cacertBundle = "${cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        # CA setup for every TLS consumer in this FOD (see env.cacertBundle).
        export CURL_CA_BUNDLE="$cacertBundle"
        export GIT_SSL_CAINFO="$cacertBundle"
        export NIX_SSL_CERT_FILE="$cacertBundle"
        export SSL_CERT_FILE="$cacertBundle"

        export HOME=$TMPDIR/home
        mkdir -p "$HOME"

        cp -r --no-preserve=mode,ownership "${src}" src
        chmod -R u+w src
        cd src

        # `lito fetch --output` stages next to the destination directory,
        # so materialize into TMPDIR first and copy into $out afterwards.
        # The git DB cache in $HOME survives retries, so a flaky GitHub TLS
        # connection only needs one lucky pass per source, not one lucky
        # attempt for all of them at once.
        ok=""
        for attempt in 1 2 3 4 5 6 7 8 9 10; do
          if lito fetch --output "$TMPDIR/bundle"; then
            ok=1
            break
          fi
          echo "lito fetch attempt $attempt failed; retrying (cache in \$HOME is reused)" >&2
        done
        [ -n "$ok" ] || {
          echo "error: lito fetch did not succeed within 10 attempts" >&2
          exit 1
        }

        for cfg in "$TMPDIR"/bundle/v1/cargo/*/config.toml; do
          [ -e "$cfg" ] || continue
          key=$(basename "$(dirname "$cfg")")
          ln -s "$key/vendor" "$TMPDIR/bundle/v1/cargo/vendor"
        done

        # nixpkgs git ships hook templates whose sample shebangs reference
        # /nix/store perl/bash; they end up in every bundled checkout's
        # .git/hooks and make the FOD output reference store paths, which
        # fixed-output derivations forbid. The samples are inert.
        find "$TMPDIR/bundle" -path '*/.git/hooks/*' -type f -delete

        # The bundled checkouts carry NO git objects of their own — lito
        # wires them to its $HOME git db through .git/objects/info/alternates
        # (a path containing $HOME, hence different per environment), and
        # .git/index, .git/logs and .git/config (whose remote url embeds
        # $HOME) all vary per run and per machine. Lito only ever runs
        # `git rev-parse --verify HEAD` on bundle checkouts, and HEAD is a
        # detached raw sha that needs neither the index, the reflog, the
        # config, nor any object — strip all of that, KEEPING an empty
        # .git/objects so the checkout stays a valid repository (git would
        # otherwise walk up to whatever enclosing repository it finds).
        find "$TMPDIR/bundle" -path '*/.git/index' -delete
        find "$TMPDIR/bundle" -type d -path '*/.git/logs' -exec rm -rf {} +
        find "$TMPDIR/bundle" -name config -path '*/.git/*' -delete
        find "$TMPDIR/bundle" -maxdepth 4 -name 'FETCH_HEAD' -path '*/.git/*' -delete
        find "$TMPDIR/bundle" -maxdepth 4 -name 'ORIG_HEAD' -path '*/.git/*' -delete
        find "$TMPDIR/bundle" -maxdepth 4 -name 'COMMIT_EDITMSG' -path '*/.git/*' -delete
        for objectsDir in $(find "$TMPDIR/bundle" -type d -path '*/.git/objects'); do
          rm -rf "$objectsDir"
          mkdir -p "$objectsDir"
        done

        # The registry index cache records every version the Registry served
        # at fetch time, so it drifts whenever upstream publishes; the lock
        # plus the v1/registry/source archives are all an offline frozen
        # build needs — drop the index.
        rm -rf "$TMPDIR/bundle/v1/registry/index"

        mkdir -p "$out"
        cp -r "$TMPDIR/bundle/." "$out/"
      '';
in
llvmPackages_22.stdenv.mkDerivation {
  pname = "waywallen";
  inherit version src;

  nativeBuildInputs = [
    lito
    git
    cargo
    rustc
    cmake
    ninja
    pkg-config
    protobuf
    glslang
    llvmPackages_22.clang-tools
    llvmPackages_22.lld
    llvmPackages_22.llvm
    makeWrapper
  ];

  buildInputs = [
    libpulseaudio
    wayland
    wayland-protocols
    ffmpeg
    libgbm
    libva
    freetype
    expat
    dav1d
    lz4
    vulkan-loader
    vulkan-headers
    libGL
    libxkbcommon
    qt6Env
  ];

  env = {
    # Mirrors waywallen's own flake devShell.
    LITO_ALLOWED_ROOTS = "/nix/store:/build";
    CMAKE_PREFIX_PATH = "${qt6Env};${libxkbcommon}";
    CMAKE_MODULE_PATH = "${qt6Env}/lib/cmake/Qt6;${qt6Env}/lib/cmake/Qt6/3rdparty/kwin";
    Qt6_DIR = "${qt6Env}/lib/cmake/Qt6";
    Qt6Protobuf_DIR = "${qt6Env}/lib/cmake/Qt6Protobuf";
    Qt6ProtobufTools_DIR = "${qt6Env}/lib/cmake/Qt6ProtobufTools";

    CFLAGS = "-I${vulkan-headers}/include -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0";
    CXXFLAGS = "-I${vulkan-headers}/include -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0";
    # Lito drives ld.lld directly (outside the cc-wrapper), so with
    # --use-env-flags these rpaths are what make the binaries runnable.
    LDFLAGS = "-Wl,-rpath,${lib.makeLibraryPath runtimeLibs}";

    CARGO_NET_OFFLINE = "true";

    # Lito runs `git` on the bundled checkouts under /nix/store, where the
    # builder user does not own the files; git's safe.directory protection
    # would abort the inspection with exit 128 otherwise.
    GIT_CONFIG_COUNT = "1";
    GIT_CONFIG_KEY_0 = "safe.directory";
    GIT_CONFIG_VALUE_0 = "*";
  };

  dontConfigure = true;

  # glibc's fortified `openat` is a static inline, which clang rejects in an
  # exported using-declaration (rstd-std's C++ modules hit this); lito's own
  # flake disables fortify for the same reason.
  hardeningDisable = [
    "fortify"
    "fortify3"
  ];

  buildPhase = ''
    runHook preBuild
    # lito caches its Registry index under $HOME/.local/share/lito; the
    # builder has no HOME, so provide a writable one.
    export HOME="$TMPDIR/lito-home"
    mkdir -p "$HOME"
    lito build \
      --frozen --offline --source-bundle ${sourceBundle} \
      --profile release --use-env-flags -j $NIX_BUILD_CORES
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    export HOME="$TMPDIR/lito-home"
    mkdir -p "$HOME"
    # Same offline flags as the build phase, otherwise lito re-resolves the
    # workspace online and dies on the first git dependency.
    lito install --frozen --offline --source-bundle ${sourceBundle} \
      --prefix "$out" --profile release
    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Wallpaper Manager for Linux";
    homepage = "https://github.com/waywallen/waywallen";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
    mainProgram = "waywallen";
  };
}
