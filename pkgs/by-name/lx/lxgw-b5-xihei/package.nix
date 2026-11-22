{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * B5 XiHei (B5溪黑), a Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 1.003
#   * TTF file installed: B5XiHei.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-b5-xihei";
  version = "1.003";

  src = fetchurl {
    url = "https://github.com/lxgw/B5XiZhi";
    hash = "sha256-xCxCTNEAVrhQ3UhvQd2llDs6p1eexyINCJL5o5HUkRM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/B5XiHei.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "B5 XiHei (B5溪黑), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/B5XiZhi";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
