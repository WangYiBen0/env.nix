{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Xiaolai (霞鹜小来), a Chinese handwriting-style font
#   * Released as a release asset from https://github.com/lxgw/kose-font/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: Xiaolai-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-xiaolai";
  version = "3.126";

  src = fetchurl {
    url = "https://github.com/lxgw/kose-font/releases/download/v${finalAttrs.version}/Xiaolai-Regular.ttf";
    hash = "sha256-4vaNrw5yd3qM9YvIPeG5hjSyUeU33b/KJLCuUNGALaI=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/Xiaolai-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Xiaolai (霞鹜小来), a Chinese handwriting-style font";
    homepage = "https://github.com/lxgw/kose-font";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
