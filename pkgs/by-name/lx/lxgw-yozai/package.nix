{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Yozai (霞鹜宋), a Chinese serif font
#   * Released as a release asset from https://github.com/lxgw/yozai-font/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: Yozai-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-yozai";
  version = "0.868";

  src = fetchurl {
    url = "https://github.com/lxgw/yozai-font/releases/download/v${finalAttrs.version}/Yozai-Regular.ttf";
    hash = "sha256-JQcZmKD+anL1TCNecUmG0lljPl/2cLGiteJkOH8zFqw=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/Yozai-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Yozai (霞鹜宋), a Chinese serif font";
    homepage = "https://github.com/lxgw/yozai-font";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
