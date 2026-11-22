{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenKai-Lite/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-lite-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-lite";
  version = "1.530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenKai-Lite/releases/download/v${finalAttrs.version}/lxgw-wenkai-lite-v${finalAttrs.version}.tar.gz";
    hash = "sha256-nTOLTtNAM5/3gMIViVZY8gq+ymT2OtvH2YhLDfrRz1A=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai Lite (霞鹜文楷 Lite), a lighter-weight variant of LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwWenKai-Lite";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
