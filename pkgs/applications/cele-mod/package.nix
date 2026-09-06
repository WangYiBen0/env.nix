{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  makeWrapper,
  autoPatchelfHook,
  copyDesktopItems,
  makeDesktopItem,
  # runtime dependencies
  glib,
  gtk3,
  gdk-pixbuf,
  cairo,
  dbus,
  pango,
  libsoup_3,
  webkitgtk_4_1,
  librsvg,
  mesa,
  libglvnd,
  glib-networking,
  dconf,
  gsettings-desktop-schemas,
  shared-mime-info,
  desktop-file-utils,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cele-mod";
  version = "1.1.11";

  src = fetchurl {
    url = "https://github.com/std-microblock/CeleMod/releases/download/v${finalAttrs.version}/CeleMod_${finalAttrs.version}_amd64.deb";
    hash = "sha256-iQSoEJ9b9tCngxnGGWqrjkgMks8ZK0LKUmRSjSy0lDM=";
  };

  nativeBuildInputs = [
    dpkg
    makeWrapper
    autoPatchelfHook
    copyDesktopItems
  ];

  buildInputs = [
    glib
    gtk3
    gdk-pixbuf
    cairo
    dbus
    pango
    libsoup_3
    webkitgtk_4_1
  ];

  unpackPhase = ''
    runHook preUnpack

    dpkg -x $src .

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 usr/bin/cele-mod $out/bin/cele-mod
    install -Dm644 usr/share/icons/hicolor/128x128/apps/cele-mod.png $out/share/icons/hicolor/128x128/apps/cele-mod.png

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "cele-mod";
      desktopName = "CeleMod";
      exec = "cele-mod";
      icon = "cele-mod";
      mimeTypes = [ "x-scheme-handler/celemod" ];
      extraConfig = {
        StartupWMClass = "cele-mod";
      };
    })
  ];

  postFixup = ''
    wrapProgram $out/bin/cele-mod \
      --prefix PATH : "${
        lib.makeBinPath [
          desktop-file-utils
          xdg-utils
        ]
      }" \
      --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          glib
          gtk3
          gdk-pixbuf
          cairo
          dbus
          pango
          libsoup_3
          webkitgtk_4_1
          librsvg
          mesa
          libglvnd
        ]
      }" \
      --set __EGL_VENDOR_LIBRARY_FILENAMES "${mesa}/share/glvnd/egl_vendor.d/50_mesa.json" \
      --set LIBGL_DRIVERS_PATH "${mesa}/lib/dri" \
      --set WEBKIT_DISABLE_DMABUF_RENDERER "1" \
      --set GDK_PIXBUF_MODULE_FILE "${gdk-pixbuf}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" \
      --prefix GDK_PIXBUF_MODULE_PATH : "${librsvg}/lib/gdk-pixbuf-2.0/2.10.0/loaders" \
      --prefix GIO_EXTRA_MODULES : "${glib-networking}/lib/gio/modules:${dconf}/lib/gio/modules" \
      --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}:${gsettings-desktop-schemas}/share/gsettings-schemas/${gsettings-desktop-schemas.name}:${shared-mime-info}/share"
  '';

  meta = {
    description = "CeleMod - An alternative mod manager for Celeste";
    homepage = "https://github.com/std-microblock/CeleMod";
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "cele-mod";
  };
})
