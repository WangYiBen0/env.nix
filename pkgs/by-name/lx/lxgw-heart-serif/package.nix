{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font
#   * Archived upstream repo; built from release asset @ 1.011
#   * TTF file installed: LXGWHeartSerif.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-heart-serif";
  version = "1.011";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwHeartSerif";
    hash = "sha256-bLkW54zvoJj7qyqrMJt9WR2PvLGewYUR+75zCwyWKC4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWHeartSerif.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font";
    homepage = "https://github.com/lxgw/LxgwHeartSerif";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
