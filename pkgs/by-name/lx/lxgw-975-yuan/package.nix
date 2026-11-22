{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW 975 Yuan (霞鹜 975 元), a Chinese sans-serif font family
#   * Released as a release asset from https://github.com/lxgw/975Yuan/releases/tag/v26.07.26
#   * TTF file(s) installed: LXGW975YuanSC-400W.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-975-yuan";
  version = "26.07.26";

  src = fetchurl {
    url = "https://github.com/lxgw/975Yuan/releases/download/${finalAttrs.version}/LXGW975YuanSC-400W.ttf";
    hash = "sha256-0U9aRToiFSXw20iHQScSy8A6hNDcRM4tItUdHBNu2aE=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGW975YuanSC-400W.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW 975 Yuan (霞鹜 975 元), a Chinese sans-serif font family";
    homepage = "https://github.com/lxgw/975Yuan";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
