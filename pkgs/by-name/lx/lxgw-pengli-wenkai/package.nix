{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Pengli WenKai (鹏丽文楷), a Chinese kai-style font
#   * Released as a release asset from https://github.com/lxgw/Pengli/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: PengliWenKai-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-pengli-wenkai";
  version = "1.034";

  src = fetchurl {
    url = "https://github.com/lxgw/Pengli/releases/download/v${finalAttrs.version}/PengliWenKai-Regular.ttf";
    hash = "sha256-6CyUaRZSb20wuPzNE3wnaLAqA4E7Nn1Mh7iOwTV1DRo=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/PengliWenKai-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Pengli WenKai (鹏丽文楷), a Chinese kai-style font";
    homepage = "https://github.com/lxgw/Pengli";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
