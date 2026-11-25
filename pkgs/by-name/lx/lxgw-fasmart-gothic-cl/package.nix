{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Fasmart Gothic (霞鹜灰明), a Chinese sans-serif font
#   * Repository lxgw/LxgwFasmartGothic publishes several TTFs per release and this
#     package installs exactly one of them; the package name describes the
#     font file, not the repository.
#   * The tag is v1.201 and the asset name carries no version of its own, so
#     both are written out here rather than derived from `version`.
#   * Deprecated: upstream repository is archived and no longer maintained.

stdenvNoCC.mkDerivation {
  pname = "lxgw-fasmart-gothic-cl";
  version = "1.201";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwFasmartGothic/releases/download/v1.201/LXGWFasmartGothicCL.ttf";
    hash = "sha256-/wKE1aYre/DfarCffcqzjMK/ilvQO3BcotNjxqd+6MA=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWFasmartGothicCL.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Fasmart Gothic (霞鹜灰明), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/LxgwFasmartGothic";
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
