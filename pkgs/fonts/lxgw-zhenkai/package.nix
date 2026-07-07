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

  meta = {
    description = "A bolder weight, AI-assisted font derived from LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwZhenKai";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
