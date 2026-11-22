{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Marker Gothic KR (霞鹜文楷 仿手写 KR), Korean variant
#   * Released as a release asset from https://github.com/lxgw/LxgwMarkerGothicKR/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: LXGWMarkerGothicKR-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-marker-gothic-kr";
  version = "1.001";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwMarkerGothicKR/releases/download/v${finalAttrs.version}/LXGWMarkerGothicKR-Regular.ttf";
    hash = "sha256-eyr2AQsIKdmKDCNmuYQOKiOA8ZfysXuJBEeNRfpWtiY=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWMarkerGothicKR-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Marker Gothic KR (霞鹜文楷 仿手写 KR), Korean variant";
    homepage = "https://github.com/lxgw/LxgwMarkerGothicKR";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
