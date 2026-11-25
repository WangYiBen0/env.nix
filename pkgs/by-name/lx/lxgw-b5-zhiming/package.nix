{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * B5 ZhiMing (B5知明), a Chinese sans-serif font
#   * Repository lxgw/B5XiZhi publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is v1.003 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-b5-zhiming";
  version = "1.003";

  src = fetchurl {
    url = "https://github.com/lxgw/B5XiZhi/releases/download/v1.003/B5ZhiMing.ttf";
    hash = "sha256-eyZKFt9O7WYIQYXnFrdtkqYSNwf5iO5Nds7PeIx3Trs=";
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
    # nixpkgs' meta.problems values are records carrying a message
    # (pkgs/stdenv/generic/problems.nix); a bare boolean makes any access to
    # meta.problems throw.
    problems.deprecated = {
      message = "Upstream repository is archived and no longer maintained";
    };
  };
}
