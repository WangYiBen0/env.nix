{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW ZhiSong (霞鹜紫宸宋), a Chinese serif font
#   * Released as a release asset from https://github.com/lxgw/LxgwZhiSong/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: LXGWZhiSongCL.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-zhisong";
  version = "1.003";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwZhiSong/releases/download/v${finalAttrs.version}/LXGWZhiSongCL.ttf";
    hash = "sha256-lOBzRMLKHN1EqKeP2TonBETzLdfr/GN6hyYfM1Xd0og=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWZhiSongCL.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW ZhiSong (霞鹜紫宸宋), a Chinese serif font";
    homepage = "https://github.com/lxgw/LxgwZhiSong";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
