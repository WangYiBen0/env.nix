{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Seal (霞鹜篆书), a Chinese seal-script font
#   * Released as a release asset from https://github.com/lxgw/LxgwSeal/releases/tag/v${finalAttrs.version}
#   * TTF file(s) installed: LXGWSeal-Regular.ttf

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-seal";
  version = "0.001-alpha.10.8";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwSeal/releases/download/v${finalAttrs.version}/LXGWSeal-Regular.ttf";
    hash = "sha256-BhAMnQr9eWEtwM9++N3vmXzOTsIr99k/fPI4ygi6wp4=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWSeal-Regular.ttf

    runHook postInstall
  '';

  # Every published tag is `v0.001-alpha.N.M`, and nix-update rejects
  # pre-release tags unless told to accept them ("Found an unstable version
  # v0.001-alpha.10.8, which is being ignored"). The flag has to be here
  # rather than on the bot's command line: --use-update-script runs this
  # script and then re-detects the version itself, so a failure inside it
  # aborts the package just the same.
  passthru.updateScript = nix-update-script {
    extraArgs = [
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "LXGW Seal (霞鹜篆书), a Chinese seal-script font";
    homepage = "https://github.com/lxgw/LxgwSeal";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
