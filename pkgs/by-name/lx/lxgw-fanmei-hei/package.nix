{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Fanmei (梵米), a Chinese sans-serif font
#   * Repository lxgw/Fanmei publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is v1.000 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-fanmei-hei";
  version = "1.000";

  src = fetchurl {
    url = "https://github.com/lxgw/Fanmei/releases/download/v1.000/Fanmei-Hei.ttf";
    hash = "sha256-sxdHWw/As8X67PBxdkDfb2+1KV1MLTCUDNmWJMs27l4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/Fanmei-Hei.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Fanmei (梵米), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/Fanmei";
    license = lib.licenses.bsd0;
    platforms = lib.platforms.all;
    # nixpkgs' meta.problems values are records carrying a message
    # (pkgs/stdenv/generic/problems.nix); a bare boolean makes any access to
    # meta.problems throw.
    problems.deprecated = {
      message = "Upstream repository is archived and no longer maintained";
    };
  };
}
