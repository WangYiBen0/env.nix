{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font
#   * Repository lxgw/LxgwHeartSerif publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is v1.011 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-heart-serif-mn";
  version = "1.011";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwHeartSerif/releases/download/v1.011/LXGWHeartSerifMN.ttf";
    hash = "sha256-BegoJFNung54sfxggDPMWIWjYQcUjepgKX3t22Q/nqk=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWHeartSerifMN.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Heart Serif (霞鹜文楷心宋), a Chinese serif font";
    homepage = "https://github.com/lxgw/LxgwHeartSerif";
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
