{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  callPackage,
  qt5,
  makeDesktopItem,
  copyDesktopItems,
  prelink,
  coreutils,
  # DingTalk dependencies (from jeffguorg/yakkhini NUR)
  alsa-lib,
  apr,
  aprutil,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  curl,
  dbus,
  e2fsprogs,
  fontconfig,
  freetype,
  fribidi,
  gdk-pixbuf,
  glib,
  gtkglext,
  gnutls,
  graphite2,
  gtk3,
  harfbuzz,
  icu63,
  krb5,
  libdrm,
  libgcrypt,
  libGLU,
  libglvnd,
  libidn2,
  libinput,
  libjpeg,
  libpng,
  libpsl,
  libpulseaudio,
  libssh2,
  libthai,
  libxcrypt-legacy,
  libxkbcommon,
  mesa,
  mtdev,
  nghttp2,
  nspr,
  nss,
  openldap,
  pango,
  pcre2,
  rtmpdump,
  udev,
  util-linux,
  libICE,
  libSM,
  libX11,
  libxcb,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXinerama,
  libXmu,
  libXrandr,
  libXrender,
  libXScrnSaver,
  libXt,
  libXtst,
  xcbutilimage,
  xcbutilkeysyms,
  xcbutilrenderutil,
  xcbutilwm,
  perl,
}:
let
  # OpenSSL 1.1.1 - required by DingTalk binaries (EOL but needed for compatibility)
  openssl_1_1 = stdenv.mkDerivation rec {
    pname = "openssl";
    version = "1.1.1w";

    src = fetchurl {
      url = "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-${version}.tar.gz";
      hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
    };

    nativeBuildInputs = [
      perl
      coreutils
    ];

    # OpenSSL uses ./config instead of ./configure
    configurePhase = ''
      # Fix the config script to use the correct env path
      substituteInPlace config --replace "/usr/bin/env" "${coreutils}/bin/env"
      ./config \
        --prefix=$out \
        --openssldir=$out/etc/ssl \
        shared \
        no-ssl3 \
        no-ssl3-method \
        no-zlib \
        enable-ec_nistp_64_gcc_128 \
        enable-tls1_3
    '';

    buildPhase = ''
      make
    '';

    installPhase = ''
      make install_sw
    '';

    # Disable tests to speed up build
    doCheck = false;

    meta = with lib; {
      description = "OpenSSL 1.1.1 - cryptography and SSL/TLS toolkit (legacy)";
      homepage = "https://www.openssl.org/";
      license = licenses.openssl;
      platforms = platforms.linux;
    };
  };

  # Version from jeffguorg (updated to latest)
  version = "8.2.8.260818002";

  # Multi-arch support from jeffguorg
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";

  # URL pattern from both packages
  url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_${arch}.deb";

  # Hashes for both architectures (from yakkhini and jeffguorg)
  hash =
    if stdenv.hostPlatform.isAarch64 then
      "sha256-placeholder-aarch64-hash"
    else
      "sha256-iNrWB7u3pykYOZORydU67fz6Om2rAffQZZ5iwcoyZ48=";

  src = fetchurl {
    inherit url hash;
  };

  # Wayland screenshare support from yakkhini
  dingtalk-wayland-screenshare = callPackage ./wayland-screenshare.nix { };

  libraries = [
    alsa-lib
    apr
    aprutil
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    curl
    dbus
    e2fsprogs
    fontconfig
    freetype
    fribidi
    gdk-pixbuf
    glib
    gtkglext
    gnutls
    graphite2
    gtk3
    harfbuzz
    icu63
    krb5
    libdrm
    libgcrypt
    libGLU
    libglvnd
    libidn2
    libinput
    libjpeg
    libpng
    libpsl
    libpulseaudio
    libssh2
    libthai
    libxcrypt-legacy
    libxkbcommon
    mesa
    mtdev
    nghttp2
    nspr
    nss
    openldap
    openssl_1_1
    pango
    pcre2
    qt5.qtbase
    qt5.qtmultimedia
    qt5.qtsvg
    qt5.qtx11extras
    rtmpdump
    udev
    util-linux
    libICE
    libSM
    libX11
    libxcb
    libXcomposite
    libXcursor
    libXdamage
    libXext
    libXfixes
    libXi
    libXinerama
    libXmu
    libXrandr
    libXrender
    libXScrnSaver
    libXt
    libXtst
    xcbutilimage
    xcbutilkeysyms
    xcbutilrenderutil
    xcbutilwm
  ];
in
stdenv.mkDerivation (_finalAttrs: {
  pname = "dingtalk";
  inherit version src;

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    prelink
    qt5.wrapQtAppsHook
    copyDesktopItems
    dpkg
  ];
  buildInputs = libraries;

  # We will append QT wrapper args to our own wrapper
  dontWrapQtApps = true;

  unpackPhase = ''
    runHook preUnpack

    dpkg -x $src .

    mv opt/apps/com.alibabainc.dingtalk/files/version version
    mv opt/apps/com.alibabainc.dingtalk/files/*-Release.* release
    mv opt/apps/com.alibabainc.dingtalk/entries entries
    mv opt/apps/com.alibabainc.dingtalk/files/logo.ico logo.ico

    # Cleanup bundled libs that conflict with system ones
    rm -f release/{*.a,*.la,*.prl,dingtalk_crash_report,dingtalk_updater,libapr*,libcrypto.so.*,libcurl.so.*}
    rm -f release/{libdouble-conversion.so.*,libEGL*,libfontconfig*,libfreetype*,libfribidi*,libgbm.*,libgdk*,libGLES*}
    rm -f release/{libgtk*,libgtk-x11-2.0.so.*,libharfbuzz*,libicu*,libidn2*,libjpeg*,libm.so.*,libnghttp2*}
    rm -f release/{libpango-1.0.*,libpangocairo-1.0.*,libpangoft2-1.0.*,libpcre2*,libpng*,libpsl*,libQt5*,libssh2*}
    rm -f release/{libssl.*,libstdc++.so.6,libstdc++*,libunistring*,libz*}
    rm -rf release/{engines-1_1,imageformats,platform*,swiftshader,xcbglintegrations}
    rm -rf release/Resources/{i18n/tool/*.exe,qss/mac}

    runHook postUnpack
  '';

  installPhase = ''
        runHook preInstall

        install -Dm644 version $out/version

        # Move libraries
        # DingTalk relies on (some of) the exact libraries it ships with
        mv release $out/lib

        # Entrypoint with input method support (from yakkhini)
        mkdir -p $out/bin
        cat > $out/bin/dingtalk <<'EOF'
    #!/usr/bin/env bash
    if [[ "$XMODIFIERS" =~ fcitx ]]; then
      export QT_IM_MODULE=fcitx
      export GTK_IM_MODULE=fcitx
    elif [[ "$XMODIFIERS" =~ ibus ]]; then
      export QT_IM_MODULE=ibus
      export GTK_IM_MODULE=ibus
      export IBUS_USE_PORTAL=1
    fi

    exec "$0.bin" "$@"
    EOF
        chmod +x $out/bin/dingtalk

        makeWrapper $out/lib/com.alibabainc.dingtalk $out/bin/dingtalk.bin \
          --argv0 "com.alibabainc.dingtalk" \
          "''${qtWrapperArgs[@]}" \
          --chdir $out/lib \
          --unset WAYLAND_DISPLAY \
          --set QT_QPA_PLATFORM "xcb" \
          --set QT_AUTO_SCREEN_SCALE_FACTOR 1 \
          --prefix LD_PRELOAD : "${dingtalk-wayland-screenshare}/lib/libdingtalkhook.so" \
          --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath libraries}"

        # Icons
        install -Dm644 $out/lib/Resources/image/common/about/logo.png $out/share/pixmaps/dingtalk.png
        cp logo.ico $out/share/pixmaps/dingtalk.ico

        runHook postInstall
  '';

  postFixup = ''
    # Fix executable stack issues (from yakkhini)
    execstack -c $out/lib/dingtalk_dll.so
    execstack -c $out/lib/libconference_new.so
  '';

  passthru = { inherit dingtalk-wayland-screenshare; };

  desktopItems = [
    (makeDesktopItem {
      name = "dingtalk";
      desktopName = "Dingtalk";
      genericName = "dingtalk";
      categories = [
        "Chat"
        "Office"
      ];
      exec = "dingtalk %u";
      icon = "dingtalk";
      keywords = [ "dingtalk" ];
      mimeTypes = [ "x-scheme-handler/dingtalk" ];
      extraConfig = {
        "Name[zh_CN]" = "钉钉";
        "Name[zh_TW]" = "釘釘";
        "Comment" = "DingTalk - Enterprise communication and collaboration platform";
        "Comment[zh_CN]" = "钉钉 - 企业通讯与协作平台";
        "Comment[zh_TW]" = "釘釘 - 企業通訊與協作平台";
      };
    })
  ];

  meta = with lib; {
    maintainers = [ xddxdd ];
    description = "DingTalk (钉钉) - Official enterprise communication platform by Alibaba";
    homepage = "https://www.dingtalk.com/";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    license = licenses.unfreeRedistributable;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "dingtalk";
  };
})
