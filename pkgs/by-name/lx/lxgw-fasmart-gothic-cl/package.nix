{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Fasmart Gothic (霞鹜灰明), a Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 1.201
#   * TTF file installed: LXGWFasmartGothicCL.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-fasmart-gothic-cl";
  version = "1.201";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwFasmartGothic";
    hash = "sha256-RZHmHkvdvv0pw3IsZaNrCYa9KpZkjL0SuI+t1qrAnQg=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWFasmartGothicCL.ttf

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
