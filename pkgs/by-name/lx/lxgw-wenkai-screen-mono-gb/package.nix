{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW WenKai Screen Mono GB (霞鹜文楷屏幕阅读版等宽 GB), monospace GB variant of WenKai Screen
#   * Released as a release asset from https://github.com/lxgw/LxgwWenKai-Screen/releases/tag/v${finalAttrs.version}
#   * TTF file installed: LXGWWenKaiMonoGBScreen.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-screen-mono-gb";
  version = "1.530";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v${finalAttrs.version}/LXGWWenKaiMonoGBScreen.ttf";
    hash = "sha256-LNqPudso1bP4ko5GTkp76dE3+rbpOs0ERBsDWM4MOyY=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWWenKaiMonoGBScreen.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW WenKai Screen Mono GB (霞鹜文楷屏幕阅读版等宽 GB), monospace GB variant of WenKai Screen";
    homepage = "https://github.com/lxgw/LxgwWenKai-Screen";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
