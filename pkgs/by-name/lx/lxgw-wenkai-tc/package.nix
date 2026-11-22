{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenkaiTC/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-tc-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai-tc";
  version = "1.530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenkaiTC/releases/download/v${finalAttrs.version}/lxgw-wenkai-tc-v${finalAttrs.version}.tar.gz";
    hash = "sha256-sUv6mOzG8YgNwTuWQfS1ZFoxA+MQZ0Vsr6oFxceKVEM=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai TC (霞鹜文楷 TC), Traditional Chinese variant of LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwWenkaiTC";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
