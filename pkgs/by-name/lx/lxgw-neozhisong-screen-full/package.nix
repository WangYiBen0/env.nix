{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo XiZhi Screen (霞鹜新溪知屏), a Chinese font optimized for screens
#   * Archived upstream repo; built from release asset @ 26.11.11
#   * TTF file installed: LXGWNeoZhiSongScreenFull.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-neo-zhi-song-screen-full";
  version = "26.11.11";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoXiZhi-Screen";
    hash = "sha256-MEPVMn24emQfHd4zwb/HtuGEb/osqeHtq9aPIjS1nR8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWNeoZhiSongScreenFull.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Neo XiZhi Screen (霞鹜新溪知屏), a Chinese font optimized for screens";
    homepage = "https://github.com/lxgw/LxgwNeoXiZhi-Screen";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
