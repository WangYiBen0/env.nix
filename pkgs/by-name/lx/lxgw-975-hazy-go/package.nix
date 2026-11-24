{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
  p7zip,
}:

# Upstream packaging contract:
#   * 975 Hazy Go (975雾凇Go), a Chinese sans-serif font
#   * Archived upstream repo. The release tag carries the "-SC" (simplified
#     Chinese) suffix but the asset name does not: tag v2.01-SC publishes
#     Lxgw975HazyGoSC-TTFs-2.01.7z. `version` is therefore the bare number
#     and the tag is spelled out around it below.
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-hazy-go";
  version = "2.01";

  src = fetchurl {
    url = "https://github.com/lxgw/975HazyGo/releases/download/v${finalAttrs.version}-SC/Lxgw975HazyGoSC-TTFs-${finalAttrs.version}.7z";
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

  passthru.updateScript = nix-update-script {
    # releases.atom reports the tag ("v2.01-SC"), so without the regex the
    # "-SC" lands inside `version` and both the download tag and the asset
    # name come out wrong. Keep only the number.
    extraArgs = [
      "--version-regex"
      "v?([0-9.]+)-SC"
    ];
  };

  meta = {
    description = "975 Hazy Go (975雾凇Go), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/975HazyGo";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
