{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * Sim XiZhi (细溪知), a Chinese font
#   * Repository lxgw/SimXiZhi publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is v1.103 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-sim-zhi-song";
  version = "1.103";

  src = fetchurl {
    url = "https://github.com/lxgw/SimXiZhi/releases/download/v1.103/SimZhiSong.ttf";
    hash = "sha256-Q/l68d9ck8RVDZlJrIXuurdhsXUH7NRrArU3aCtuaxM=";
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
    # nixpkgs' meta.problems values are records carrying a message
    # (pkgs/stdenv/generic/problems.nix); a bare boolean makes any access to
    # meta.problems throw.
    problems.deprecated = {
      message = "Upstream repository is archived and no longer maintained";
    };
  };
}
