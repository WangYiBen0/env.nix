{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Black Sugar Plum Candy (霞鹜黑糖李子糖), a Chinese handwriting font
#   * Archived upstream repo; built from git snapshot @ c925837
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-black-sugar-plum-candy";
  version = "c9258372b2a0cef8a6bd49e2275336c27eb0bc82";

  src = fetchzip {
    url = "https://github.com/lxgw/BlackSugarPlumCandy/archive/${finalAttrs.version}.tar.gz";
    hash = "sha256-AMrg5nZlDEpTAWPiA9c//F5furKiJsFWzTMd8F9ZuuQ=";
  };

  dontUnpack = false;

  nativeBuildInputs = [ ];

  installPhase = ''
    runHook preInstall

    find $src -name '*.ttf' -exec install -Dm644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Black Sugar Plum Candy (霞鹜黑糖李子糖), a Chinese handwriting font";
    homepage = "https://github.com/lxgw/BlackSugarPlumCandy";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
