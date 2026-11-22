{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font
#   * Archived upstream repo; built from release asset @ 1.011
#   * TTF file installed: LXGWHeartSerifMN.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-heart-serif-mn";
  version = "1.011";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwHeartSerif";
    hash = "sha256-9jAe99U14mBleYneROmGI5tNy0eXAbcy0ooe1Yrypsg=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWHeartSerifMN.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font";
    homepage = "https://github.com/lxgw/LxgwHeartSerif";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
