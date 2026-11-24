{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW WenKai Screen GB (霞鹜文楷屏幕阅读版 GB), GB variant with mainland Chinese glyph forms
#   * Released as a release asset from https://github.com/lxgw/LxgwWenKai-Screen/releases/tag/v${finalAttrs.version}
#   * TTF file installed: LXGWWenKaiGBScreen.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-screen-gb";
  version = "1.530";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v${finalAttrs.version}/LXGWWenKaiGBScreen.ttf";
    hash = "sha256-DfQAmsnc5us7jLTE6Q3me7l0XomSolXAOljdX+Px5QM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWWenKaiGBScreen.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW WenKai Screen GB (霞鹜文楷屏幕阅读版 GB), GB variant with mainland Chinese glyph forms";
    homepage = "https://github.com/lxgw/LxgwWenKai-Screen";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
