{
  lib,
  fetchurl,
  nix-update-script,
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

  passthru.updateScript = nix-update-script {
    # The update script re-invokes nix-update without --flake, which cannot
    # eval this flake; always point it back at the local flake.
    extraArgs = [ "--flake" ];
  };

  meta = {
    description = "A Chinese serif font derived from IPAmj Mincho";
    homepage = "https://github.com/lxgw/LxgwNeoZhiSong";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
