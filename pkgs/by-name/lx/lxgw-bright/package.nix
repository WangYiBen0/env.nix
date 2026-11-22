{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Bright (霞鹜亮黑), a Chinese sans-serif font
#   * Archived upstream repo; built from git snapshot @ 26.10.22
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-bright";
  version = "26.10.22";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwBright/archive/refs/tags/${finalAttrs.version}.tar.gz";
    hash = "sha256-4s3sGMpRf8glCthz4Nol6f9bOMoLik0Z2m6C9PHOoL8=";
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
    description = "LXGW Bright (霞鹜亮黑), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/LxgwBright";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
