{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Fasmart Gothic (霞鹜灰明), a Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 1.201
#   * TTF file installed: LXGWFasmartGothicMN.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-fasmart-gothic-mn";
  version = "1.201";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwFasmartGothic";
    hash = "sha256-OEefvwzq2hc5l735/zp8uxmOwCuK4EuCH+aNJ9rKP4Q=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWFasmartGothicMN.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Fasmart Gothic (霞鹜灰明), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/LxgwFasmartGothic";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
