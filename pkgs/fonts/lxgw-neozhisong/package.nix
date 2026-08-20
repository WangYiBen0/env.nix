{
  lib,
  fetchurl,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neozhisong";
  version = "1.067";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoZhiSong/releases/download/v${finalAttrs.version}/LXGWNeoZhiSong.ttf";
    hash = "sha256-MrOY+cYnjE7TT0Ewd63SwvPIQDTUY68rnLmPEsTCxs0=";
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
