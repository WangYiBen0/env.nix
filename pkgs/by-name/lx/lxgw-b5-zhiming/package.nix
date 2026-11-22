{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * B5 ZhiMing (B5知明), a Chinese sans-serif font
#   * Archived upstream repo; built from release asset @ 1.003
#   * TTF file installed: B5ZhiMing.ttf
#   * Deprecated: upstream repository is archived and no longer maintained

stdenvNoCC.mkDerivation {
  pname = "lxgw-b5-zhiming";
  version = "1.003";

  src = fetchurl {
    url = "https://github.com/lxgw/B5XiZhi";
    hash = "sha256-KZwwFmvt3XiNju42xqgOCJ9OvJTtmkjgP7oL/Ha6eYI=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/B5ZhiMing.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "B5 ZhiMing (B5知明), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/B5XiZhi";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
    problems = {
      deprecated = true;
    };
  };
}
