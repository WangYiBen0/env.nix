{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenkaiKR/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-kr-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-kr";
  version = "0.902";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenkaiKR/releases/download/v${finalAttrs.version}/lxgw-wenkai-kr-v${finalAttrs.version}.tar.gz";
    hash = "sha256-OCPm2p3zHudnKSujLaRW14rKwZDMgxMBWkmPo+fzFPw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai KR (霞鹜文楷 KR), Korean variant of LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwWenkaiKR";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
