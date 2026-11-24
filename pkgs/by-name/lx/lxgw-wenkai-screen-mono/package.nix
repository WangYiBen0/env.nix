{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW WenKai Screen Mono (霞鹜文楷屏幕阅读版等宽), monospace variant of WenKai Screen
#   * Released as a release asset from https://github.com/lxgw/LxgwWenKai-Screen/releases/tag/v${finalAttrs.version}
#   * TTF file installed: LXGWWenKaiMonoScreen.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-screen-mono";
  version = "1.530";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwWenKai-Screen/releases/download/v${finalAttrs.version}/LXGWWenKaiMonoScreen.ttf";
    hash = "sha256-VYi4Yx5HJQszXdBJkHuCOEXvcJr2Jf8zuv4+yYtI1x8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWWenKaiMonoScreen.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW WenKai Screen Mono (霞鹜文楷屏幕阅读版等宽), monospace variant of WenKai Screen";
    homepage = "https://github.com/lxgw/LxgwWenKai-Screen";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
