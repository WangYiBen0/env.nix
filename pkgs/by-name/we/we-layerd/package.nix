{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  fetchFromGitLab,
  fetchurl,
  runCommand,
  cmake,
  pkg-config,
  makeWrapper,
  nix-update-script,
  cef-binary,
  directx-shader-compiler,
  fontconfig,
  freetype,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libdrm,
  libglvnd,
  libva,
  libxkbcommon,
  libpulseaudio,
  lz4,
  mesa,
  pango,
  vulkan-headers,
  vulkan-loader,
  wayland,
  wayland-scanner,
  wayland-protocols,
  xdotool,
}:
let
  # The C++ renderer that tag v0.2.10 pins as the
  # third_party/wallpaper-engine-renderer submodule; upstream's own
  # package/nix/flake.nix references the same commit at the tag.
  rendererRev = "89dfcd86de2dc0ae537bc136046c5ed05733e7b7";
  renderer = fetchFromGitHub {
    owner = "Aromatic05";
    repo = "wallpaper-engine-renderer";
    rev = rendererRev;
    hash = "sha256-0sDOR2GVuAuiIZKwgisatwzicjboMlqo89/L4QPRr7M=";
  };

  # nixpkgs' directx-shader-compiler ships only bin/ and lib/ — no
  # dxcapi.h — so the renderer's find_path(dxc/dxcapi.h) fails and it
  # silently builds without runtime HLSL→SPIR-V shader compilation
  # (HANABI_HAS_DXC=0), which breaks most scene wallpapers. Stage a
  # minimal DXC SDK: the nixpkgs binaries plus the two public headers
  # from the matching upstream tag, and point CMake at it via
  # -DHANABI_DXC_ROOT (the header set is exactly dxcapi.h + WinAdapter.h;
  # WinAdapter.h only pulls in the C++ standard library).
  dxcapiHeader = fetchurl {
    url = "https://raw.githubusercontent.com/microsoft/DirectXShaderCompiler/v${directx-shader-compiler.version}/include/dxc/dxcapi.h";
    hash = "sha256-qNQJZC3tSF6k/UwFXxGZoTU48Dk3VcLZWK3iga/tTKA=";
  };
  winAdapterHeader = fetchurl {
    url = "https://raw.githubusercontent.com/microsoft/DirectXShaderCompiler/v${directx-shader-compiler.version}/include/dxc/WinAdapter.h";
    hash = "sha256-9WiKFAio3owMNRdryQDyHXZ51JIhXalNpKtkPLZoZ/Q=";
  };
  dxcSdk = runCommand "directx-shader-compiler-sdk-${directx-shader-compiler.version}" { } ''
    mkdir -p "$out/include/dxc" "$out/lib" "$out/bin"
    ln -s "${directx-shader-compiler}/lib/libdxcompiler.so" "$out/lib/libdxcompiler.so"
    ln -s "${directx-shader-compiler}/lib/libdxil.so" "$out/lib/libdxil.so"
    ln -s "${directx-shader-compiler}/bin/dxc" "$out/bin/dxc"
    cp "${dxcapiHeader}" "$out/include/dxc/dxcapi.h"
    cp "${winAdapterHeader}" "$out/include/dxc/WinAdapter.h"
  '';

  # The renderer vendors its own dependencies as git submodules, which
  # GitHub archive tarballs ship as empty directories, so overlay each
  # pinned checkout exactly like upstream flake.nix's mkRendererSource.
  rendererThirdParty = {
    Eigen = fetchFromGitLab {
      owner = "libeigen";
      repo = "eigen";
      rev = "3147391d946bb4b6c68edd901f2add6ac1f31f8c";
      hash = "sha256-1/4xMetKMDOgZgzz3WMxfHUEpmdAm52RqZvz6i0mLEw=";
    };
    SPIRV-Reflect = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "SPIRV-Reflect";
      rev = "c6c0f5c9796bdef40c55065d82e0df67c38a29a4";
      hash = "sha256-wghhePlcZEwd+qXgAkdFmXe+eBLjbtQXGDmPfxsIcWc=";
    };
    glslang = fetchFromGitHub {
      owner = "KhronosGroup";
      repo = "glslang";
      rev = "9db8c369e6f49b5c00376040ba8c0cda6cbb7b4d";
      hash = "sha256-Ydw20Ztkb6N+DqO2e1uOE2pfLicVemrYX/0nPsm4Lh8=";
    };
    miniaudio = fetchFromGitHub {
      owner = "mackron";
      repo = "miniaudio";
      rev = "4a5b74bef029b3592c54b6048650ee5f972c1a48";
      hash = "sha256-EOIykyUXYcdDeTYb/Mf3xgcxEpKS4us213tEFwm5mEI=";
    };
    nlohmann = fetchFromGitHub {
      owner = "nlohmann";
      repo = "json";
      rev = "0457de21cffb298c22b629e538036bfeb96130b7";
      hash = "sha256-tXvz5ukjB+33gTw4h5AWA40hAGdkWCuKnQMiwT6LRbg=";
    };
    quickjs = fetchFromGitHub {
      owner = "quickjs-ng";
      repo = "quickjs";
      rev = "01bce21cb70c771b372ac17a8ef9920ee105e972";
      hash = "sha256-ltrHT0zwJaZXZ8+AR4ouDXVWlVzJcdDzY2wpp8PyDmU=";
    };
  };

  rendererSrc = runCommand "wallpaper-engine-renderer-source-${lib.substring 0 7 rendererRev}" { } ''
    mkdir -p "$out"
    cp -a "${renderer}/." "$out/"
    chmod -R u+w "$out"
    ${lib.concatStringsSep "\n" (
      lib.mapAttrsToList (name: source: ''
        rm -rf "$out/third_party/${name}"
        mkdir -p "$out/third_party/${name}"
        cp -a "${source}/." "$out/third_party/${name}/"
      '') rendererThirdParty
    )}
  '';

  # Prebuilt renderer library that the daemon dlopens at runtime
  # (we-layerd's build.rs validates lib/libwallpaper-engine-renderer.so
  # and lib/we-cef-helper exist when WE_LAYERD_PREBUILT_RENDERER_ROOT is
  # set, instead of building the renderer from the submodule).
  wallpaper-engine-renderer = stdenv.mkDerivation {
    pname = "wallpaper-engine-renderer";
    version = "0-unstable";
    src = rendererSrc;

    nativeBuildInputs = [
      cmake
      pkg-config
      wayland-scanner
    ];

    buildInputs = [
      cef-binary
      directx-shader-compiler
      fontconfig
      freetype
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-bad
      gtk3
      libdrm
      libglvnd
      libva
      libxkbcommon
      lz4
      mesa
      pango
      vulkan-headers
      vulkan-loader
      wayland
      wayland-protocols
    ];

    cmakeFlags = [
      "-DBUILD_WEWEB=ON"
      "-DBUILD_QML=OFF"
      "-DBUILD_TESTING=OFF"
      "-DHANABI_BUILD_VENDORED_DXC=OFF"
      # Vendored DXC is not a submodule of the pinned renderer rev; use
      # the staged nixpkgs SDK instead (see dxcSdk above).
      "-DHANABI_DXC_ROOT=${dxcSdk}"
      "-DCEF_ROOT=${cef-binary}"
      "-DCMAKE_INSTALL_LIBDIR=lib"
    ];
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "we-layerd";
  version = "0.2.10";

  src = fetchFromGitHub {
    owner = "Aromatic05";
    repo = "we-layerd";
    rev = "v${finalAttrs.version}";
    hash = "sha256-FOCNhY2nc0CE8TVfWvLfZsd39ARHcIl4qo1T46GDxHY=";
  };

  cargoLock.lockFile = ./Cargo.lock;

  cargoBuildFlags = [
    "-p"
    "we-layerd"
    "-p"
    "we-gui"
  ];

  nativeBuildInputs = [
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    cef-binary
    directx-shader-compiler
    fontconfig
    freetype
    gst_all_1.gstreamer
    gst_all_1.gst-libav
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-good
    gtk3
    libayatana-appindicator
    libdrm
    libglvnd
    libva
    libxkbcommon
    libpulseaudio
    lz4
    mesa
    pango
    vulkan-headers
    vulkan-loader
    wayland
    wayland-protocols
    xdotool
  ];

  preBuild = ''
    export WE_LAYERD_INSTALL_PREFIX=/usr
    export WE_LAYERD_PREBUILT_RENDERER_ROOT=${wallpaper-engine-renderer}
  '';

  installPhase = ''
    mkdir -p $out/bin $out/lib $out/share/applications $out/share/icons/hicolor/scalable/apps
    mkdir -p $out/share/gnome-shell/extensions/we-layerd@aromatic $out/lib/systemd/user
    cargoTarget=target/${stdenv.hostPlatform.rust.rustcTarget}/release
    install -Dm755 "$cargoTarget/we-layerd" $out/bin/we-layerd
    install -Dm755 "$cargoTarget/we-gui" $out/bin/we-gui
    cp -a ${wallpaper-engine-renderer}/lib/. $out/lib/
    cp -a contrib/gnome-shell-extension/we-layerd@aromatic/. \
      $out/share/gnome-shell/extensions/we-layerd@aromatic/
    install -Dm644 apps/we-gui/assets/we-gui.desktop $out/share/applications/we-gui.desktop
    install -Dm644 apps/we-gui/assets/we-gui-logo.svg \
      $out/share/icons/hicolor/scalable/apps/we-gui.svg
    install -Dm644 contrib/systemd/we-layerd.service $out/lib/systemd/user/we-layerd.service
    substituteInPlace $out/lib/systemd/user/we-layerd.service \
      --replace-fail /usr/bin/we-layerd $out/bin/we-layerd
  '';

  postFixup = ''
    gstreamerPluginPath="${lib.getLib gst_all_1.gstreamer}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-base}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-bad}/lib/gstreamer-1.0:${gst_all_1.gst-plugins-good}/lib/gstreamer-1.0:${gst_all_1.gst-libav}/lib/gstreamer-1.0"
    wrapProgram $out/bin/we-layerd \
      --set CEF_ROOT "${cef-binary}" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$gstreamerPluginPath" \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ wayland ]}"
    # we-gui spawns the daemon by looking up "we-layerd" in PATH
    # (apps/we-gui/src/services/runtime.rs), which never contains the
    # package's own bin dir.
    wrapProgram $out/bin/we-gui \
      --set CEF_ROOT "${cef-binary}" \
      --prefix PATH : "$out/bin" \
      --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "$gstreamerPluginPath" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          libayatana-appindicator
          wayland
        ]
      }"
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Wayland daemon and GUI for Wallpaper Engine wallpapers";
    homepage = "https://github.com/Aromatic05/we-layerd";
    # Upstream has not published a license yet; their Debian packaging
    # declares "all-rights-reserved" for the source tree.
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "we-layerd";
  };
})
