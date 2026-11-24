{
  lib,
  fetchurl,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * lxgw/LxgwZhenKai stopped shipping built TTF release assets with v0.828
#     (2026-11-16): the release contains only the FontCreator project file
#     FCP/LXGWZhenKaiSlabGB-Regular.fcp, a proprietary binary format
#     (High-Logic FontCreator) for which no free-software toolchain exists to
#     compile it into a TTF. The repository itself tracks no .ttf/.otf either.
#   * v0.827 (2026-10-13) is the last release that still ships
#     LXGWZhenKaiSlabGB-Regular.ttf; this package builds from that asset.
#
#   This package is intentionally broken: upstream no longer publishes a
#   buildable font artifact, so there is nothing to construct from source and
#   nothing to auto-update to. passthru.updateScript is null so the daily
#   `Update pkgs` bot is not pointed at v0.828+ (whose only asset is the
#   unbuildable .fcp) and does not abort the whole run there.
#
#   https://github.com/lxgw/LxgwZhenKai/releases/tag/v0.827
#   https://github.com/lxgw/LxgwZhenKai/releases/tag/v0.828

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-zhenkai";
  version = "0.828";

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

  passthru.updateScript = null;

  meta = {
    description = "Slab variant of a bolder weight, AI-assisted font derived from LXGW Wenkai";
    homepage = "https://github.com/lxgw/LxgwZhenKai";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
    broken = true;
    brokenDescription = "Upstream ships only a FontCreator .fcp project since v0.828; no TTF to build from source.";
  };
})
