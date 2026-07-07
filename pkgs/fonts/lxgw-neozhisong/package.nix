{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neozhisong";
  version = "1.066";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoZhiSong/releases/download/v${finalAttrs.version}/LXGWNeoZhiSong.ttf";
    hash = "sha256-lZNqCG/3rY6LMCiN7A4g6BeXb6EnXY8RqFseYUTI0Bc=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWNeoZhiSong.ttf

    runHook postInstall
  '';

  meta = {
    description = "A Chinese serif font derived from IPAmj Mincho";
    homepage = "https://github.com/lxgw/LxgwNeoZhiSong";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
