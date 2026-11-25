{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo ZhiSong Screen, a Chinese font from the LxgwNeoXiZhi-Screen release.
#     One repository publishes four TTFs (NeoXiHei / NeoZhiSong, each plain
#     and "Full"), and this package installs exactly one of them;
#     lxgw-neozhisong-screen names the font, not the repository.
#   * The tag is a bare date with no "v" prefix, and the asset name carries
#     no version of its own, so both are spelled out below.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-neo-zhi-song-screen";
  version = "26.11.11";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoXiZhi-Screen/releases/download/26.11.11/LXGWNeoZhiSongScreen.ttf";
    hash = "sha256-o4IM85zmqthgCI5/Enq3d6y0EnvAZBChuBn0OPt6W2M=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWNeoZhiSongScreen.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Neo ZhiSong Screen, a Chinese font optimized for screens";
    homepage = "https://github.com/lxgw/LxgwNeoXiZhi-Screen";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    # nixpkgs' meta.problems values are records carrying a message
    # (pkgs/stdenv/generic/problems.nix); a bare boolean makes any access to
    # meta.problems throw.
    problems.deprecated = {
      message = "Upstream repository is archived and no longer maintained";
    };
  };
}
