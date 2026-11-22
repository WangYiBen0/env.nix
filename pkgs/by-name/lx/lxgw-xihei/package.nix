{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW XiHei (霞鹜溪黑), a Chinese sans-serif font
#   * Released as a release asset from https://github.com/lxgw/LxgwXiHei/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: LXGWXiHeiCL.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-xihei";
  version = "1.003";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwXiHei/releases/download/v${finalAttrs.version}/LXGWXiHeiCL.ttf";
    hash = "sha256-PA6EAdrJCFUdJyquHuMIkXWdrGQtDSqFSqMF3tN0v+E=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWXiHeiCL.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW XiHei (霞鹜溪黑), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/LxgwXiHei";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
