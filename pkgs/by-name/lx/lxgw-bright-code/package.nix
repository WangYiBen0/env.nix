{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Bright Code (霞鹜亮黑代码), a monospace Chinese sans-serif font
#   * Archived upstream repo; built from git snapshot @ 26.10.22
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-bright-code";
  version = "26.10.22";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwBright-Code/archive/refs/tags/${finalAttrs.version}.tar.gz";
    hash = "sha256-Q5D2ItDm9ol2VxR9vvGmm0ew3YQlUonf6cxTEV1NpGY=";
  };

  dontUnpack = false;

  nativeBuildInputs = [ ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "LXGW Bright Code (霞鹜亮黑代码), a monospace Chinese sans-serif font";
    homepage = "https://github.com/lxgw/LxgwBright-Code";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
