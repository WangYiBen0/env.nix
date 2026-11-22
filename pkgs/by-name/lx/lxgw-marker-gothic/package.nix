{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
  unzip,
}:

# Upstream packaging contract:
#   * Release asset is a zip: https://github.com/lxgw/LxgwMarkerGothic/releases/tag/v${finalAttrs.version}
#   * zip unpacks to LxgwMarkerGothic-v${finalAttrs.version}/fonts/ttf/LXGWMarkerGothic-Regular.ttf (+ OFL.txt)
#   * unzip is a nativeBuildInput because installPhase calls unzip on $src

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-marker-gothic";
  version = "1.012";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwMarkerGothic/releases/download/v${finalAttrs.version}/LxgwMarkerGothic-v${finalAttrs.version}.zip";
    hash = "sha256-oc28NHHbc5DyNYzhjbFzqiGQb2dlJDS/m+rmGREgHaE=";
  };

  dontUnpack = true;

  nativeBuildInputs = [ unzip ];

  installPhase = ''
    runHook preInstall

    unzip $src
    install -Dm644 LxgwMarkerGothic-v${finalAttrs.version}/fonts/ttf/LXGWMarkerGothic-Regular.ttf $out/share/fonts/truetype/LXGWMarkerGothic-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Marker Gothic (霞鹜文楷 仿手写), a Chinese handwriting-style font";
    homepage = "https://github.com/lxgw/LxgwMarkerGothic";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
