{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo XiHei Code (霞鹜新溪黑代码), a monospace Chinese sans-serif font
#   * Repository lxgw/NeoXiHei-Code publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is 26.11.10 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-neo-xi-hei-code";
  version = "26.11.10";

  src = fetchurl {
    url = "https://github.com/lxgw/NeoXiHei-Code/releases/download/26.11.10/NeoXiHeiCode-Regular.ttf";
    hash = "sha256-bsD3xvR6tQ9Jw89bpB2yjpSRZvLmnWiW5vlIW+9RrRo=";
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
    # nixpkgs' meta.problems values are records carrying a message
    # (pkgs/stdenv/generic/problems.nix); a bare boolean makes any access to
    # meta.problems throw.
    problems.deprecated = {
      message = "Upstream repository is archived and no longer maintained";
    };
  };
}
