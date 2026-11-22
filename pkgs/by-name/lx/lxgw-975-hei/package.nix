{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW 975 Hei (霞鹜 975 黑), a Chinese sans-serif font family
#   * Released as a release asset from https://github.com/lxgw/975Hei/releases/tag/v26.06.20
#   * TTF file(s) installed: LXGW975HeiSC-200W.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-975-hei";
  version = "26.06.20";

  src = fetchurl {
    url = "https://github.com/lxgw/975Hei/releases/download/${finalAttrs.version}/LXGW975HeiSC-200W.ttf";
    hash = "sha256-nxuHw8UoQSf4F3qlFHY6ZHfqJTse5LBZIzorMb6bfsA=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGW975HeiSC-200W.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW 975 Hei (霞鹜 975 黑), a Chinese sans-serif font family";
    homepage = "https://github.com/lxgw/975Hei";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
