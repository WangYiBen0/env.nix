{
  lib,
  stdenv,
  fetchurl,
  callPackage,
  writeShellScript,
  makeDesktopItem,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  prelink,
  # Linux runtime libraries.  Derived from the NEEDED entries of the shipped
  # ELF files plus the libraries CEF/ffmpeg dlopen; anything the .deb itself
  # bundles is deliberately absent (see `unpackPhase`).
  alsa-lib,
  apr,
  aprutil,
  at-spi2-core,
  cairo,
  cups,
  curl,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gnutls,
  gtk3,
  libdrm,
  libepoxy,
  libgbm,
  libglvnd,
  libidn2,
  libopus,
  libpulseaudio,
  libuuid,
  libxkbcommon,
  nspr,
  nss,
  pango,
  pipewire,
  qt5,
  udev,
  zlib,
  libICE,
  libSM,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libXtst,
  libxcb,
  libxau,
  libxdmcp,
  # Darwin: the .dmg wraps an installer .pkg (xar + pbzx + cpio payload).
  undmg,
  xar,
  pbzx,
  cpio,
}:
let
  pname = "dingtalk";

  # Linux (.deb) release.  Upstream bundles its own OpenSSL 1.1, Qt 5.15, GTK 3
  # and ICU 63; those copies are kept as built (the same choice Flathub makes),
  # so no legacy OpenSSL has to be compiled here.
  version = "9.0.0.261030001";
  arch = if stdenv.hostPlatform.isAarch64 then "arm64" else "amd64";
  linuxSrc = fetchurl {
    url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/xc_dingtalk_update/linux_deb/Release/com.alibabainc.dingtalk_${version}_${arch}.deb";
    # 9.0 is not on the redirect feed yet (it still hands out 8.3.1), so these
    # were prefetched from the explicit release URLs.
    hash =
      if stdenv.hostPlatform.isAarch64 then
        "sha256-UBLTApjSR20sIFXifdx3sdyeUCsEGPqYjpkMNDb94Io="
      else
        "sha256-kaBDBzrxGg8GPTvixL2m37Y8Mkfv1mypBjCv3h8RLY8=";
  };

  # macOS release: a universal .dmg wrapping DingTalkInstaller.pkg.
  darwinVersion = "9.0.5";
  darwinInstaller = "59563623";
  darwinHash = "sha256-j8IfSYxWlSvS/m0DXPyXqkfHXeitAgRJuF8v2X2v4io=";
  darwinSrc = fetchurl {
    url = "https://dtapp-pub.dingtalk.com/dingtalk-desktop/mac_dmg/Release/DingTalk_v${darwinVersion}-Installer_${darwinInstaller}_universal.dmg";
    hash = darwinHash;
  };

  dingtalk-wayland-screenshare = callPackage ./wayland-screenshare.nix { };

  # Both download pages redirect to the real archive, and the Location header
  # carries the version in the filename:
  #   linux: https://www.dingtalk.com/win/d/qd=linux_amd64 -> ..._<version>_amd64.deb
  #   macos: https://www.dingtalk.com/mac/d/                -> DingTalk_v<version>-Installer_<build>_universal.dmg
  #
  # One script updates both, because the update bot runs on Linux and the macOS
  # pin would otherwise never move.  Downloading (and hashing) the .dmg works on
  # any host.
  updateScript = writeShellScript "update-dingtalk" ''
    set -euo pipefail

    expr=pkgs/by-name/di/dingtalk/package.nix
    [ -f "$expr" ] || { echo "run this from the flake root" >&2; exit 1; }

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    resolve() {
      # $1 = redirector URL, prints the final Location.
      curl -sS -D "$tmpdir/headers" -o /dev/null -A 'Mozilla/5.0' "$1"
      grep -i '^location:' "$tmpdir/headers" |
        tail -1 |
        sed 's/^[^:]*:[[:space:]]*//' |
        tr -d '\r\n'
    }

    prefetch() {
      nix store prefetch-file --json --name "$(basename "$1")" "$1" | jq -r '.hash'
    }

    # The feed lags the explicit release URLs (9.0 is published under its full
    # name while qd=linux_amd64 still answers 8.3.1), so an unchecked
    # inequality would silently downgrade the package.  Returns 0 when the
    # update is acceptable, 1 when it must be skipped.
    accept() {
      local current=$1 latest=$2
      [ "''${UPDATE_ALLOW_DOWNGRADE:-0}" = 1 ] && return 0
      [ "$(printf '%s\n%s\n' "$current" "$latest" | sort -V | tail -1)" = "$latest" ] && return 0
      echo "feed only offers $latest, which is older than $current; refusing to downgrade"
      return 1
    }

    rewrite_hash_block() {
      # $1 = hash for the aarch64 branch, $2 = the default (amd64) hash.
      # Only a bare `hash =` line starts the block; `hash = darwinHash;` must
      # not match.
      awk -v ha="$1" -v hd="$2" '
        BEGIN { replaced = 0 }
        !replaced && /^    hash =$/ {
          print "    hash ="
          print "      if stdenv.hostPlatform.isAarch64 then"
          print "        \"" ha "\""
          print "      else"
          print "        \"" hd "\";"
          replaced = 1
          next
        }
        replaced == 1 && /";$/ { replaced = 2; next }
        replaced == 1 { next }
        { print }
      ' "$expr" > "$expr.tmp" && mv "$expr.tmp" "$expr"
    }

    changed=0

    echo ">> Linux: querying dingtalk.com ..."
    deb_url=$(resolve 'https://www.dingtalk.com/win/d/qd=linux_amd64')
    [ -n "$deb_url" ] || { echo "error: could not resolve the .deb URL" >&2; exit 1; }
    new=$(printf '%s' "$(basename "$deb_url")" | sed -n 's/^com\.alibabainc\.dingtalk_\(.*\)_amd64\.deb$/\1/p')
    [ -n "$new" ] || { echo "error: cannot parse a version from $deb_url" >&2; exit 1; }
    current=$(sed -n 's/^  version = "\(.*\)";$/\1/p' "$expr")
    if [ "$new" = "$current" ]; then
      echo "   already at $current"
    elif ! accept "$current" "$new"; then
      echo "   keeping $current"
    else
      echo "   $current -> $new"
      hash=$(prefetch "$deb_url")
      hash_arm64=$(prefetch "$(printf '%s' "$deb_url" | sed 's/_amd64\.deb/_arm64.deb/')")
      for h in "$hash" "$hash_arm64"; do
        case "$h" in
          sha256-*) ;;
          *)
            echo "error: prefetch failed for $deb_url" >&2
            exit 1
            ;;
        esac
      done
      sed -i "s|^  version = \"[^\"]*\";|  version = \"$new\";|" "$expr"
      # Rewrite the whole per-architecture block: its shape is not guaranteed
      # to survive nixfmt, and a loose pattern used to clobber unrelated pins.
      rewrite_hash_block "$hash_arm64" "$hash"
      changed=1
    fi

    echo ">> macOS: querying dingtalk.com ..."
    dmg_url=$(resolve 'https://www.dingtalk.com/mac/d/')
    [ -n "$dmg_url" ] || { echo "error: could not resolve the .dmg URL" >&2; exit 1; }
    dmg_file=$(basename "$dmg_url")
    new=$(printf '%s' "$dmg_file" | sed -n 's/^DingTalk_v\(.*\)-Installer_[0-9]*_universal\.dmg$/\1/p')
    installer=$(printf '%s' "$dmg_file" | sed -n 's/^DingTalk_v.*-Installer_\([0-9]*\)_universal\.dmg$/\1/p')
    [ -n "$new" ] && [ -n "$installer" ] || {
      echo "error: cannot parse version/installer from $dmg_file" >&2
      exit 1
    }
    current=$(sed -n 's/^  darwinVersion = "\(.*\)";$/\1/p' "$expr")
    if [ "$new" = "$current" ]; then
      echo "   already at $current"
    elif ! accept "$current" "$new"; then
      echo "   keeping $current"
    else
      echo "   $current -> $new (build $installer)"
      hash=$(prefetch "$dmg_url")
      case "$hash" in
        sha256-*) ;;
        *)
          echo "error: prefetch failed for $dmg_url" >&2
          exit 1
          ;;
      esac
      sed -i "s|^  darwinVersion = \"[^\"]*\";|  darwinVersion = \"$new\";|" "$expr"
      sed -i "s|^  darwinInstaller = \"[^\"]*\";|  darwinInstaller = \"$installer\";|" "$expr"
      sed -i "s|^  darwinHash = \"[^\"]*\";|  darwinHash = \"$hash\";|" "$expr"
      changed=1
    fi

    [ "$changed" = 1 ] || echo ">> nothing to do"
  '';

  linuxLibraries = [
    alsa-lib
    apr
    aprutil
    at-spi2-core
    cairo
    cups
    curl
    dbus
    expat
    gdk-pixbuf
    glib
    gnutls
    gtk3
    libdrm
    libepoxy
    libgbm
    libglvnd
    libidn2
    libopus
    libpulseaudio
    libuuid
    libxkbcommon
    nspr
    nss
    pango
    # dlopen'd rather than NEEDED: libcef enumerates devices through libudev,
    # libmeeting_sdk hands captured frames to libpipewire.
    pipewire
    udev
    zlib
    qt5.qtbase
    qt5.qtmultimedia
    qt5.qtsvg
    qt5.qtx11extras
    libICE
    libSM
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libXtst
    libxcb
    libxau
    libxdmcp
  ];
in
if stdenv.hostPlatform.isDarwin then
  stdenv.mkDerivation {
    inherit pname;
    version = darwinVersion;
    src = darwinSrc;

    nativeBuildInputs = [
      undmg
      xar
      pbzx
      cpio
      makeWrapper
    ];

    # undmg unwraps the .dmg to DingTalkInstaller.pkg, a xar archive whose
    # Payload is a pbzx-compressed cpio holding `Applications/DingTalk.app`.
    unpackPhase = ''
      runHook preUnpack

      undmg $src
      xar -xf DingTalkInstaller.pkg
      pbzx -n DingTalk.pkg/Payload | cpio -idm --quiet

      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall

      mkdir -p $out/Applications $out/bin
      mv Applications/DingTalk.app $out/Applications/
      makeWrapper $out/Applications/DingTalk.app/Contents/MacOS/DingTalk $out/bin/dingtalk

      runHook postInstall
    '';

    passthru.updateScript = updateScript;

    meta = with lib; {
      description = "DingTalk (钉钉) - Official enterprise communication platform by Alibaba";
      homepage = "https://www.dingtalk.com/";
      platforms = platforms.darwin;
      license = licenses.unfree;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
      mainProgram = "dingtalk";
    };
  }
else
  stdenv.mkDerivation {
    inherit pname version;
    src = linuxSrc;

    nativeBuildInputs = [
      autoPatchelfHook
      makeWrapper
      # Provides `execstack`.
      prelink
      qt5.wrapQtAppsHook
      copyDesktopItems
      dpkg
    ];

    buildInputs = linuxLibraries;

    # We create our own wrapper instead of the default Qt wrapper.
    dontWrapQtApps = true;

    unpackPhase = ''
      runHook preUnpack

      dpkg -x $src .

      mv opt/apps/com.alibabainc.dingtalk/files/version version
      mv opt/apps/com.alibabainc.dingtalk/files/*-Release.* release
      mv opt/apps/com.alibabainc.dingtalk/entries entries
      mv opt/apps/com.alibabainc.dingtalk/files/logo.ico logo.ico

      # Drop the libraries nixpkgs provides (the .deb copies are unpatched and
      # would shadow the patched ones), plus dead weight:
      #  - `doctor` is the standalone diagnostics GUI.  Nothing ever execs it
      #    (it is only reachable through a `dingtalk://...open_doctor` link),
      #    and it is the sole consumer of GTK 2 / gtkglext / pangox, so keeping
      #    it would drag `gtk2` -- marked broken upstream, removed in NixOS
      #    27.05 -- into every build.
      #  - `dingtalk_crash_report` and `dingtalk_updater` are superseded by the
      #    system crash handler and by nixpkgs.
      # Everything else upstream ships (its own OpenSSL 1.1, Qt 5.15, GTK 3,
      # ICU 63, harfbuzz, zlib, ffmpeg, CEF) is kept exactly as built.
      rm -f release/{*.a,*.la,*.prl,dingtalk_crash_report,dingtalk_updater,doctor,libapr*,libcurl.so.*}
      rm -f release/{libdouble-conversion.so.*,libEGL*,libGLES*,libfontconfig*,libfreetype*,libfribidi*,libgbm.*,libgdk*,libgtk*,libharfbuzz*}
      rm -f release/{libicu*,libidn2*,libjpeg*,libm.so.*,libnghttp2*,libpango*,libpangox*,libpcre2*,libpng*,libpsl*}
      rm -f release/{libQt5*,libssh2*,libstdc++*,libunistring*,libz*}
      rm -rf release/{engines-1_1,imageformats,platform*,swiftshader,xcbglintegrations,doctor_config}
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
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath linuxLibraries}"

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
      inherit updateScript;
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
