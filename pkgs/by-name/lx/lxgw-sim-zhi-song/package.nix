{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Sim XiZhi (细溪知), a Chinese font
#   * Archived upstream repo; built from release asset @ 1.103
#   * TTF file installed: SimZhiSong.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-sim-zhi-song";
  version = "1.103";

  src = fetchurl {
    url = "https://github.com/lxgw/SimXiZhi";
    hash = "sha256-gCwSskyWIBirT1Jl30WCAZ5pXcARYAnEBDspA70i4a4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/SimZhiSong.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Sim XiZhi (细溪知), a Chinese font";
    homepage = "https://github.com/lxgw/SimXiZhi";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
