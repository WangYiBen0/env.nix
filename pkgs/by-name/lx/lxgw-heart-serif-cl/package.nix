{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font
#   * Archived upstream repo; built from release asset @ 1.011
#   * TTF file installed: LXGWHeartSerifCL.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-heart-serif-cl";
  version = "1.011";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwHeartSerif";
    hash = "sha256-pq5ewhhE8Yu3jNmU16gAiyY7xwl9deWS8wysimzePj8=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWHeartSerifCL.ttf

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
