{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-zhenkai";
  version = "0.825";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwZhenKai/releases/download/v${finalAttrs.version}/LXGWZhenKaiGB-Regular.ttf";
    hash = "sha256-QIdpAqfOJSaKtxCtj+bitjvAAqpLaNIv1F/BJDcmztU=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWZhenKaiGB-Regular.ttf

    runHook postInstall
  '';

  # Upstream discontinued the non-Slab variants with v0.826 and only ships
  # the Slab build since; this package pins the last maintained release, so
  # auto-updates are disabled.
  # https://github.com/lxgw/LxgwZhenKai/releases/tag/v0.826
  passthru.updateScript = [
    "echo"
    "lxgw-zhenkai: frozen at 0.825, upstream only ships the Slab build since v0.826"
  ];

  meta = {
    description = "A bolder weight, AI-assisted font derived from LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwZhenKai";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
