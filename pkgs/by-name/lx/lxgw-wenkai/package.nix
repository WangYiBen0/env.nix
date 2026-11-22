{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * 6 TTF weights + OFL.txt shipped as a tar.gz release asset from
#     https://github.com/lxgw/LxgwWenKai/releases/tag/v${finalAttrs.version}
#   * tar.gz unpacks to lxgw-wenkai-v${finalAttrs.version}/; install every *.ttf into
#     $out/share/fonts/truetype/

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-wenkai";
  version = "1.530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwWenKai/releases/download/v${finalAttrs.version}/lxgw-wenkai-v${finalAttrs.version}.tar.gz";
    hash = "sha256-7xP35XCQeMIvk89+/3fnDbsafqLgn3xXPzor0E/dkdc=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;
    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;
    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;
    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;
    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;
    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Wenkai (霞鹜文楷), a Chinese serif font derived from Source Han Serif";
    homepage = "https://github.com/lxgw/LxgwWenKai";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
