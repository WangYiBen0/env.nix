{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW WenKai Screen (霞鹜文楷屏幕阅读版), optimized for screen reading
#   * Released as a release asset from https://github.com/lxgw/LxgwWenKai-Screen/releases/tag/v${finalAttrs.version}
#   * TTF file installed: LXGWWenKaiScreen.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-screen";
  version = "1.315";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v${finalAttrs.version}/LXGWWenKaiScreen.ttf";
    hash = "sha256-4K797LHyUPzC9hFBicryPxru0ndYsw0YqA1wMGXmSW0=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWWenKaiScreen.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW WenKai Screen (霞鹜文楷屏幕阅读版), optimized for screen reading";
    homepage = "https://github.com/lxgw/LxgwWenKai-Screen";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
