{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenkaiGB/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-gb-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-gb";
  version = "1.530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenkaiGB/releases/download/v${finalAttrs.version}/lxgw-wenkai-gb-v${finalAttrs.version}.tar.gz";
    hash = "sha256-hjt8eJTPSyJDkXIrda3urHIR0N5lgLhrWVsbTP2m2is=";
  };

  installPhase = ''
    runHook preInstall

    find $src -name '*.ttf' -exec install -Dm644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai GB (霞鹜文楷 GB), GB 2312 subset of LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwWenkaiGB";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
