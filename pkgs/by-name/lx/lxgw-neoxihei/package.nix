{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo XiHei (霞鹜新溪黑), a Chinese sans-serif font derived from IPAex Gothic
#   * Released as a release asset from https://github.com/lxgw/LxgwNeoXiHei/releases/tag/v${finalAttrs.version}
#   * TTF file installed: NeoXiHei-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neo-xi-hei";
  version = "1.309";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoXiHei/releases/download/v${finalAttrs.version}/LXGWNeoXiHei.ttf";
    hash = "sha256-LpOFF9G7LSPEUoKbrGwoMKRXfZ7rutIkRcXEGR60MI8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/NeoXiHei-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Neo XiHei (霞鹜新溪黑), a Chinese sans-serif font derived from IPAex Gothic";
    homepage = "https://github.com/lxgw/LxgwNeoXiHei";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
