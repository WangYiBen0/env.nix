{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenkaiGB-Lite/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-gb-lite-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-gb-lite";
  version = "1.530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenkaiGB-Lite/releases/download/v${finalAttrs.version}/lxgw-wenkai-gb-lite-v${finalAttrs.version}.tar.gz";
    hash = "sha256-j93ItIrzNPX73X8CtHWD86OqptiM8LARX+KXpofnuFI=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai GB Lite (霞鹜文楷 GB Lite), GB 2312 subset of LXGW Wenkai Lite";
    homepage = "https://github.com/lxgw/LxgwWenkaiGB-Lite";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
