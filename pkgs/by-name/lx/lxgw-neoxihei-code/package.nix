{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo XiHei Code (霞鹜新溪黑代码), a monospace Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 26.11.10
#   * TTF file installed: NeoXiHeiCode-Regular.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-neo-xi-hei-code";
  version = "26.11.10";

  src = fetchurl {
    url = "https://github.com/lxgw/NeoXiHei-Code";
    hash = "sha256-WLR9bJnmsFJDPBcg5Rti0IO9uIdkWlefkt7ZdTzOkh0=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/NeoXiHeiCode-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Neo XiHei Code (霞鹜新溪黑代码), a monospace Chinese sans-serif font";
    homepage = "https://github.com/lxgw/NeoXiHei-Code";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
