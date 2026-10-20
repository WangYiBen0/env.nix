# OpenWallpaper ships three cooperating components that upstream builds
# separately (see build_dist.sh / docs/install.md):
#
#   1. wallpaperd         C Wayland daemon, CMake, everything vendored via
#                         git submodules (SDL, SDL_image, SDL_shadercross,
#                         wasm-micro-runtime, cava, fftw3, sds, yyjson)
#   2. wpe-compile        Go CLI that imports Wallpaper Engine scenes; it
#                         embeds a prebuilt WASM scene module
#                         (wpe-compile/module/scene.wasm) via //go:embed
#   3. owui               Go GTK4/libadwaita GUI, spawns the other two
#
# We build each one as its own derivation and merge them, so the four
# binaries land in one bin/ directory next to owui.desktop.
{
  lib,
  stdenv,
  runCommand,
  alsa-lib,
  buildGoModule,
  cmake,
  fetchgit,
  glib,
  git,
  gobject-introspection,
  gtk4,
  jq,
  libGL,
  libadwaita,
  libpulseaudio,
  libxkbcommon,
  llvmPackages_22,
  makeWrapper,
  mpv,
  mpv-unwrapped,
  ninja,
  pipewire,
  pkg-config,
  pkgsCross,
  portaudio,
  python3,
  curl,
  shaderc,
  symlinkJoin,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-scanner,
  wrapGAppsHook4,
  writeShellScript,
}:

let
  # Upstream has no release tags; pin the repo HEAD as of 2026-07-20.
  # nix-update-script is deliberately not wired up: there is no tag or
  # stable branch to follow, so updates are manual rev bumps.
  rev = "e854dbbcb9e39f6927aca85f06685008da536350";
  commitDate = "2026-07-20";
  version = "0-unstable-${commitDate}";

  # One fetch covers the whole tree: wallpaperd's vendored dependencies
  # are git submodules, some of them nested (SDL_image vendors
  # libpng/zlib/webp/..., SDL_shadercross vendors SPIRV-Cross and a DXC
  # checkout it does not use at build time), so fetchSubmodules pulls in
  # every external/ directory CMake expects to find.
  src = fetchgit {
    name = "openwallpaper-src";
    url = "https://github.com/mechakotik/openwallpaper";
    inherit rev;
    hash = "sha256-0s0U6UapGvhefzwjJMt1gQXYkKM2nuGDnQf6rH5p7l0=";
    fetchSubmodules = true;

    # nix-prefetch-git's `submodule update --depth 1` can silently leave
    # submodules empty when the (flaky) clone of one of them fails; the
    # result still gets its content hash, which would freeze a broken
    # tree into the store. Fail the fetch loudly instead so a rerun can
    # produce a complete tree.
    postFetch = ''
      for f in \
        wallpaperd/external/SDL/CMakeLists.txt \
        wallpaperd/external/SDL_image/external/libpng/CMakeLists.txt \
        wallpaperd/external/SDL_shadercross/external/SPIRV-Cross/CMakeLists.txt \
        wallpaperd/external/cava/cavacore.c \
        wallpaperd/external/fftw3/CMakeLists.txt \
        wallpaperd/external/sds/sds.c \
        wallpaperd/external/wasm-micro-runtime/wamr-compiler/CMakeLists.txt \
        wallpaperd/external/yyjson/CMakeLists.txt
      do
        test -s "$out/$f" || { echo "missing submodule content: $f" >&2; exit 1; }
      done
    '';
  };

  # --- embedded WASM scene module ------------------------------------------

  # wpe-compile embeds wpe-compile/module/scene.wasm (//go:embed in
  # scene.go), which upstream compiles with
  #   clang --target=wasm32-wasi --sysroot=<wasi-libc>
  # (see wpe-compile/module/build.sh). The top-level nixpkgs wasilibc attr
  # refuses to evaluate on x86_64-linux (unsupported host); the wasi32
  # cross scope carries the wasm32 target build.
  wasiLibc = pkgsCross.wasi32.wasilibc;

  # clang expects its compiler builtins archive inside the resource dir,
  # and nixpkgs' clang resource dir ships none for wasm32. Overlay the
  # wasm32 builtins from compiler-rt into a -resource-dir override.
  wasiCompilerRt = pkgsCross.wasi32.llvmPackages_22.compiler-rt;
  wasiClangResource = runCommand "openwallpaper-wasi-clang-resource" { } ''
    mkdir -p $out/lib/wasm32-unknown-wasi
    ln -s ${llvmPackages_22.clang-unwrapped.lib}/lib/clang/22/include $out/include
    ln -s ${wasiCompilerRt}/lib/wasip1/libclang_rt.builtins-wasm32.a \
      $out/lib/wasm32-unknown-wasi/libclang_rt.builtins.a
  '';

  # clang's wasi driver looks up headers and libs under
  # <sysroot>/{include,lib}/wasm32-wasi, while nixpkgs' wasilibc uses the
  # wasm32-wasip1 spelling; expose both names in one merged sysroot.
  wasiSysroot = runCommand "openwallpaper-wasi-sysroot" { } ''
    mkdir -p $out/include $out/lib
    ln -s ${wasiLibc.dev}/include/wasm32-wasip1 $out/include/wasm32-wasip1
    ln -s ${wasiLibc.dev}/include/wasm32-wasip1 $out/include/wasm32-wasi
    ln -s ${wasiLibc}/lib/wasm32-wasip1 $out/lib/wasm32-wasip1
    ln -s ${wasiLibc}/lib/wasm32-wasip1 $out/lib/wasm32-wasi
  '';

  sceneWasm = stdenv.mkDerivation {
    pname = "openwallpaper-scene-wasm";
    inherit version src;

    sourceRoot = "${src.name}/wpe-compile/module";

    nativeBuildInputs = [
      # lld provides wasm-ld, which the -flto link needs on PATH.
      llvmPackages_22.clang-unwrapped
      llvmPackages_22.lld
    ];

    # build.sh word-splits WASM_CC, so this must stay one string of
    # space-separated words.
    WASM_CC = "${llvmPackages_22.clang-unwrapped}/bin/clang --target=wasm32-wasi --sysroot=${wasiSysroot} -resource-dir=${wasiClangResource}";

    buildPhase = ''
      runHook preBuild
      sh ./build.sh
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm644 scene.wasm $out/share/openwallpaper/scene.wasm
      runHook postInstall
    '';
  };

  # --- wallpaperd -----------------------------------------------------------

  wallpaperd = stdenv.mkDerivation {
    pname = "openwallpaper-daemon";
    inherit version src;

    sourceRoot = "${src.name}/wallpaperd";

    nativeBuildInputs = [
      cmake
      makeWrapper
      ninja
      pkg-config
      # SPIRV-Tools (vendored inside SDL_shadercross) generates tables with
      # find_package(Python3 Interpreter REQUIRED) at configure time.
      python3
      wayland-scanner
    ];

    buildInputs = [
      # portaudio's pkg-config link pulls libasound into wallpaperd's own
      # DT_NEEDED, so the ALSA library must be a direct input.
      alsa-lib
      libGL
      libpulseaudio
      libxkbcommon
      # wamrc (bundled WASM AOT compiler) links the LLVM shared library.
      # Upstream's Docker build instead clones LLVM release/22.x and
      # statically links it (WD_WAMRC_STATIC_LLVM=ON), which cannot work
      # in the sandbox; the default path below uses find_package(LLVM).
      llvmPackages_22.llvm
      mpv-unwrapped
      pipewire
      portaudio
      vulkan-headers
      vulkan-loader
      wayland
    ];

    cmakeFlags = [
      # fftw3's CMakeLists.txt declares cmake_minimum_required(VERSION 3.0),
      # rejected by CMake 4.
      "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
      "-DLLVM_DIR=${llvmPackages_22.llvm.dev}/lib/cmake/llvm"
      "-DLLVM_LINK_LLVM_DYLIB=ON"
    ];

    # Upstream bug: the audio-visualizer block never sets
    # WD_AUDIO_VISUALIZER_LIBS, so the cava input backends are compiled in
    # but their libraries are never linked and the final link dies with
    # undefined pw_*/pa_*/Pa_* symbols. pkg_check_modules is used without
    # IMPORTED_TARGET, so link the discovered backends through the
    # <PREFIX>_LIBRARIES variables (empty when a backend was not found)
    # and add their library dirs.
    postPatch = ''
      substituteInPlace CMakeLists.txt --replace-fail \
        'target_link_libraries(wallpaperd PRIVATE ''${WD_AUDIO_VISUALIZER_LIBS} Threads::Threads)' \
        'target_link_libraries(wallpaperd PRIVATE ''${WD_AUDIO_VISUALIZER_LIBS} Threads::Threads
            ''${PIPEWIRE_LIBRARIES} ''${PULSE_LIBRARIES} ''${PORTAUDIO_LIBRARIES})
        target_link_directories(wallpaperd PRIVATE
            ''${PIPEWIRE_LIBRARY_DIRS} ''${PULSE_LIBRARY_DIRS} ''${PORTAUDIO_LIBRARY_DIRS})'
    '';

    postInstall = ''
      # SDL3 is linked statically and dlopen()s the Vulkan/GL loaders at
      # runtime, and dynamic_api.c dlopen()s libmpv for video wallpapers;
      # PATH keeps WD_WAMRC_BINARY ("wallpaperd-wamrc") resolvable when
      # wallpaperd is started outside a desktop session.
      wrapProgram $out/bin/wallpaperd \
        --prefix PATH : "$out/bin" \
        --prefix LD_LIBRARY_PATH : ${
          lib.makeLibraryPath [
            libGL
            mpv-unwrapped
            vulkan-loader
          ]
        }
    '';
  };

  # --- wpe-compile ----------------------------------------------------------

  wpeCompile = buildGoModule {
    pname = "wpe-compile";
    inherit version src;

    modRoot = "wpe-compile";
    vendorHash = "sha256-svEM8URDrUQUGpkpi9JQhMwGl4GdXAYjRaXRphSFzoA=";

    nativeBuildInputs = [ makeWrapper ];

    # The embedded scene module is a build artifact, not part of the repo;
    # place it at the //go:embed path before the Go build. This has to
    # happen in preBuild, not postPatch: buildGoModule also runs the patch
    # phase inside the go-modules fetch, where the module/ tree does not
    # exist.
    preBuild = ''
      cp ${sceneWasm}/share/openwallpaper/scene.wasm module/scene.wasm
    '';

    # Wallpaper Engine shader translation shells out to glslc at runtime.
    postInstall = ''
      wrapProgram $out/bin/wpe-compile \
        --prefix PATH : ${lib.makeBinPath [ shaderc ]}
    '';

    meta.mainProgram = "wpe-compile";
  };

  # --- owui -----------------------------------------------------------------

  owui = buildGoModule {
    pname = "owui";
    inherit version src;

    modRoot = "owui";
    vendorHash = "sha256-HrmxhicBkiysMxNfwSkwHG4FZS12Kbzh1BlnJYQXXG4=";

    nativeBuildInputs = [
      pkg-config
      wrapGAppsHook4
    ];

    # gotk4's cgo bindings pkg-config-depend on the GTK4 stack plus
    # gobject-introspection (its glib core bindings use the GI C API).
    buildInputs = [
      glib
      gobject-introspection
      gtk4
      libadwaita
    ];

    preFixup = ''
      makeWrapperArgs+=(--prefix PATH : ${lib.makeBinPath [ shaderc ]})
    '';

    meta.mainProgram = "owui";
  };
in
# --- merged package ---------------------------------------------------------
symlinkJoin {
  pname = "openwallpaper";
  inherit version;

  paths = [
    wallpaperd
    wpeCompile
    owui
  ];

  passthru = {
    # The top-level derivation is a symlinkJoin without a src of its own;
    # expose the fetchgit tree so tooling (nix-update's file detection,
    # `nix build .#openwallpaper.src`) can see it.
    inherit src;

    # Upstream has no tags, so nix-update's generic version detection
    # cannot work (--use-update-script fails with "could not find a url").
    # Walk the default branch HEAD by hand, like honk's updateScript, and
    # repair the fetchgit + Go vendor hashes through the build-error loop
    # so every update lands build-verified. GH_TOKEN dodges the
    # shared-runner IP rate limit.
    updateScript = writeShellScript "update-openwallpaper" ''
      set -euo pipefail
      export PATH="${
        lib.makeBinPath [
          jq
          curl
          git
        ]
      }:$PATH"

      tmp=$(mktemp)
      code=$(curl -sS -o "$tmp" -w '%{http_code}' \
        ''${GH_TOKEN:+-H "Authorization: Bearer ''$GH_TOKEN"} \
        https://api.github.com/repos/mechakotik/openwallpaper/commits/main)
      [ "$code" = 200 ] || { echo "error: GitHub API returned HTTP $code" >&2; exit 1; }
      rev=$(jq -r .sha "$tmp")
      date=$(jq -r .commit.author.date "$tmp" | cut -dT -f1)
      rm -f "$tmp"

      expr=pkgs/by-name/op/openwallpaper/package.nix
      [ -f "$expr" ] || { echo "run this from the flake root" >&2; exit 1; }

      old=$(sed -n 's/^  rev = "\(.*\)";$/\1/p' "$expr")
      if [ "$rev" = "$old" ]; then
        echo ">> openwallpaper is already at $rev"
        exit 0
      fi

      sed -i \
        -e "s|rev = \"[0-9a-f]\{40\}\"|rev = \"$rev\"|" \
        -e "s|commitDate = \"[0-9-]*\"|commitDate = \"$date\"|" \
        "$expr"

      # Repair the fetchgit hash and the Go vendor hashes from the
      # hash-mismatch errors instead of prefetching (the submodule tree
      # makes prefetching awkward, and the loop lands build-verified).
      err=$(mktemp)
      for i in $(seq 1 8); do
        if NIXPKGS_ALLOW_UNFREE=1 nix build --no-link \
             ".#packages.x86_64-linux.openwallpaper" 2>"$err"; then
          echo ">> openwallpaper builds against $rev"
          rm -f "$err"
          exit 0
        fi
        specified=$(awk '/^[[:space:]]*specified:/{print $2; exit}' "$err")
        got=$(awk '/^[[:space:]]*got:/{print $2; exit}' "$err")
        if [ -z "$specified" ] || [ -z "$got" ]; then
          echo "error: nix build failed without a hash mismatch:" >&2
          cat "$err" >&2
          rm -f "$err"
          exit 1
        fi
        echo ">> repairing $specified -> $got"
        sed -i "s|$specified|$got|" "$expr"
      done
      echo "error: hash mismatches did not settle after 8 repair rounds:" >&2
      cat "$err" >&2
      rm -f "$err"
      exit 1
    '';
  };

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    install -Dm644 ${src}/owui/owui.desktop $out/share/applications/owui.desktop

    # owui spawns wpe-compile, wallpaperd, mpv and killall by name; the
    # wrapper from the owui derivation only knows shaderc, so re-wrap
    # against the merged tree. The inner wrapper (wrapGAppsHook4) keeps
    # the GTK environment; this outer one only extends PATH.
    rm $out/bin/owui
    makeWrapper ${owui}/bin/owui $out/bin/owui \
      --prefix PATH : "$out/bin" \
      --prefix PATH : ${lib.makeBinPath [ mpv ]}
  '';

  meta = {
    description = "Programmable live wallpaper runtime for Wayland";
    homepage = "https://openwallpaper.org";
    # LICENSING.md: everything is GPL-3.0-or-later (LICENSE) except
    # include/openwallpaper.h, which is 0BSD (LICENSE-0BSD). Vendored
    # dependencies carry their own licenses (SDL: zlib, WAMR:
    # Apache-2.0 WITH LLVM-exception, ...).
    license = lib.licenses.gpl3Plus;
    # wamrc hardcodes WAMR_BUILD_TARGET="X86_64" upstream.
    platforms = [ "x86_64-linux" ];
    mainProgram = "wallpaperd";
  };
}
