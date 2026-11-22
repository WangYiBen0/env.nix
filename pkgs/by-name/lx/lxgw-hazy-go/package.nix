{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
  p7zip,
}:

# Upstream packaging contract:
#   * 975 Hazy Go (975雾凇Go), a Chinese sans-serif font
#   * Archived upstream repo; built from git snapshot @ 2.01-SC
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-hazy-go";
  version = "2.01-SC";

  src = fetchurl {
    url = "https://github.com/lxgw/975HazyGo/releases/download/v${finalAttrs.version}/Lxgw975HazyGoSC-TTFs-${finalAttrs.version}.7z";
    hash = "sha256-qv0kDCh4ZJN1kpMpyjypISriMu6uAcp8jP5Ad/WZ9wA=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ p7zip ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype
    7z x $src -o$out/share/fonts/truetype -y

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "975 Hazy Go (975雾凇Go), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/975HazyGo";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
