{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-zhenkai";
  version = "0.827";

  # Upstream discontinued the original (non-Slab) variants with v0.826 and
  # only ships the Slab build since; this package tracks it.
  # https://github.com/lxgw/LxgwZhenKai/releases/tag/v0.826
  src = fetchurl {
    url = "https://github.com/lxgw/LxgwZhenKai/releases/download/v${finalAttrs.version}/LXGWZhenKaiSlabGB-Regular.ttf";
    hash = "sha256-v06ow5tReERpAgEgElcV0wdRNyM/4ze10Kcyf538A70=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWZhenKaiSlabGB-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Slab variant of a bolder weight, AI-assisted font derived from LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwZhenKai";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
