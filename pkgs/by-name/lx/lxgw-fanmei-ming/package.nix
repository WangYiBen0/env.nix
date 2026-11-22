{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Fanmei (梵米), a Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 1.000
#   * TTF file installed: Fanmei-Ming.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-fanmei-ming";
  version = "1.000";

  src = fetchurl {
    url = "https://github.com/lxgw/Fanmei";
    hash = "sha256-MwVnA6wQCwuzngJpdAckM5EGpEW75mo8lWCOCYPf86M=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/Fanmei-Ming.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fanmei (梵米), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/Fanmei";
    license = lib.licenses.bsd0;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
