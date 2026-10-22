{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neozhisong";
  version = "1.068";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoZhiSong/releases/download/v${finalAttrs.version}/LXGWNeoZhiSong.ttf";
    hash = "sha256-rkgNWSlLajGBc+NYGljRo4XPOtRGemWQsFs3R+opKjo=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWNeoZhiSong.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "A Chinese serif font derived from IPAmj Mincho";
    homepage = "https://github.com/lxgw/LxgwNeoZhiSong";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
