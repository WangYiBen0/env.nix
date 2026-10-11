{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  callPackage,
  makeDesktopItem,
  copyDesktopItems,
  writeShellScript,
  prelink,
  coreutils,
  perl,
  qt5,
  # Heavy GUI/electron dependencies
  alsa-lib,
  apr,
  aprutil,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  e2fsprogs,
  expat,
  fontconfig,
  freetype,
  fribidi,
  gdk-pixbuf,
  glib,
  gnutls,
  gtk3,
  gtk2,
  gtkglext,
  harfbuzz,
  icu63,
  krb5,
  libdrm,
  libgcrypt,
  libGL,
  libGLU,
  libglvnd,
  libidn2,
  libinput,
  libjpeg,
  libopus,
  libpng,
  libpsl,
  libpulseaudio,
  libssh2,
  libthai,
  libxkbcommon,
  mesa,
  mtdev,
  nspr,
  nss,
  openldap,
  pango,
  pcre2,
  pipewire,
  rtmpdump,
  udev,
  wayland,
  zlib,
  # X11 / xcb (lowercase by-name attrs; the old xorg.* aliases are not in scope)
  libICE,
  libSM,
  libX11,
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
  libxcb,
  libxau,
  libxdmcp,
  libxcb-util,
  libxcb-image,
  libxcb-keysyms,
  libxcb-render-util,
  libxcb-wm,
}:
let
  # DingTalk still ships binaries that link against OpenSSL 1.1.1.  The
  # nixpkgs attribute has been removed, so build the legacy version locally.
  openssl_1_1 = stdenv.mkDerivation (finalAttrs: {
    pname = "openssl";
    version = "1.1.1w";

    src = fetchurl {
      url = "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-${finalAttrs.version}.tar.gz";
      hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
    };

    nativeBuildInputs = [
      perl
      coreutils
    ];

    configurePhase = ''
      substituteInPlace config --replace-fail "/usr/bin/env" "${coreutils}/bin/env"
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

    meta = with lib; {
      description = "OpenSSL 1.1.1 - cryptography and SSL/TLS toolkit (legacy)";
      homepage = "https://www.openssl.org/";
      license = licenses.openssl;
      platforms = platforms.linux;
    };
  });

  version = "8.2.8.260818002";
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";
  url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_${arch}.deb";
  hash =
    if stdenv.hostPlatform.isAarch64 then
      "sha256-Iiaeqtql59q2okwcN7ryxFpXIiGjg5qf9KSHB5gS2rw="
    else
      "sha256-iNrWB7u3pykYOZORydU67fz6Om2rAffQZZ5iwcoyZ48=";

  src = fetchurl {
    inherit url hash;
  };

  dingtalk-wayland-screenshare = callPackage ./wayland-screenshare.nix { };

  # Libraries used at runtime by the prebuilt binary.  The list is derived
  # from the actual NEEDED entries of the shipped ELF files (binary scanning,
  # not guessed from the upstream package -- there is no fhsenv).
  libraries = [
    # CEF / embedded browser
    alsa-lib
    apr
    aprutil
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    fribidi
    gdk-pixbuf
    glib
    gnutls
    gtk3
    harfbuzz
    krb5
    libdrm
    libgcrypt
    libGL
    libGLU
    libglvnd
    libinput
    libjpeg
    libopus
    libpng
    libpulseaudio
    libthai
    libxkbcommon
    mesa
    mtdev
    nspr
    nss
    openldap
    pango
    pipewire
    udev
    wayland

    # Old/legacy libs required by the bundled binaries
    e2fsprogs
    gtk2
    gtkglext
    icu63
    libidn2
    libpsl
    libssh2
    openssl_1_1
    pcre2
    rtmpdump
    zlib

    # Qt / multimedia / X11
    qt5.qtbase
    qt5.qtmultimedia
    qt5.qtsvg
    qt5.qtx11extras
    libICE
    libSM
    libX11
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
    libxcb-util
    libxcb-image
    libxcb-keysyms
    libxcb-render-util
    libxcb-wm
    libxcb
    libxau
    libxdmcp
  ];
in
stdenv.mkDerivation {
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

  # We create our own wrapper instead of the default Qt wrapper.
  dontWrapQtApps = true;

  unpackPhase = ''
    runHook preUnpack

    dpkg -x $src .

    mv opt/apps/com.alibabainc.dingtalk/files/version version
    mv opt/apps/com.alibabainc.dingtalk/files/*-Release.* release
    mv opt/apps/com.alibabainc.dingtalk/entries entries
    mv opt/apps/com.alibabainc.dingtalk/files/logo.ico logo.ico

    # Remove bundled libs that conflict with the ones we provide from nixpkgs.
    # Keep DingTalk's own private libs and the CEF bundle.
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

    # Move the full release tree into $out/lib.
    mv release $out/lib

    # Entrypoint that sets input method variables based on XMODIFIERS.
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
    install -Dm644 logo.ico $out/share/pixmaps/dingtalk.ico

    runHook postInstall
  '';

  postFixup = ''
    # Fix executable stack issues in bundled binaries.
    execstack -c $out/lib/dingtalk_dll.so
    execstack -c $out/lib/libconference_new.so
  '';

  passthru = {
    inherit dingtalk-wayland-screenshare;
    # The DingTalk download page redirects to the actual .deb URL:
    #   https://www.dingtalk.com/win/d/qd=linux_amd64  ->  302 to .deb
    # and the Location header encodes the version in the filename.
    updateScript = writeShellScript "update-dingtalk" ''
      set -euo pipefail

      expr=pkgs/by-name/di/dingtalk/package.nix
      [ -f "$expr" ] || { echo "run this from the flake root" >&2; exit 1; }

      echo ">> querying latest dingtalk version from dingtalk.com ..."

      tmpdir=$(mktemp -d)
      trap 'rm -rf "$tmpdir"' EXIT

      # Dump headers only, then take the final Location after all redirects.
      curl -sS -D "$tmpdir/headers" -o /dev/null \
        'https://www.dingtalk.com/win/d/qd=linux_amd64'

      deb_url=$(
        grep -i '^location:' "$tmpdir/headers" |
          tail -1 |
          sed 's/^[^:]*:[[:space:]]*//' |
          tr -d '\r\n'
      )
      [ -n "$deb_url" ] || { echo "error: could not determine latest download URL" >&2; exit 1; }

      file=$(basename "$deb_url")
      version=$(printf '%s' "$file" | sed -n 's/^com\.alibabainc\.dingtalk_\(.*\)_amd64\.deb$/\1/p')
      [ -n "$version" ] || { echo "error: could not parse version from URL: $deb_url" >&2; exit 1; }

      echo ">> latest version: $version"

      current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$expr")
      if [ "$version" = "$current" ]; then
        echo "already at $version, nothing to do"
        exit 0
      fi
      echo ">> updating $current -> $version"

      # Prefetch the amd64 .deb so we can pin its hash.
      echo ">> prefetching amd64 .deb to compute hash ..."
      hash=$(
        nix store prefetch-file --json \
          --name "com.alibabainc.dingtalk_''${version}_amd64.deb" \
          "$deb_url" |
          jq -r '.hash'
      )
      [ -n "$hash" ] && [ "$hash" != "null" ] || {
        echo "error: failed to compute hash for $deb_url" >&2
        exit 1
      }
      echo ">> hash: $hash"

      # Only replace a real SRI hash (ends with '=') so the aarch64
      # placeholder stays untouched.
      sed -i \
        -e "s|version = \".*\";|version = \"$version\";|" \
        -e "s|\"sha256-[^\"]*=\";|\"$hash\";|" \
        "$expr"

      echo ">> updated $current -> $version (hash: $hash)"
    '';
  };

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
    description = "DingTalk (钉钉) - Official enterprise communication platform by Alibaba";
    homepage = "https://www.dingtalk.com/";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    license = licenses.unfree;
    sourceProvenance = [ sourceTypes.binaryNativeCode ];
    mainProgram = "dingtalk";
  };
}
