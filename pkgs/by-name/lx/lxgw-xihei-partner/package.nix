{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW XiHei Partner (霞鹜溪黑搭档), a Chinese sans-serif font
#   * Archived upstream repo; built from git snapshot @ d57e84b
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-xihei-partner";
  version = "d57e84bbb8aea78b60d5c3e88e010e6c91ae8583";

  src = fetchzip {
    url = "https://github.com/lxgw/XiHeiPartner/archive/${finalAttrs.version}.tar.gz";
    hash = "sha256-XO19Ni9WGL6jwDIr+8dlo47N/zZn5/gXldxh+HSZ8uk=";
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
    description = "LXGW XiHei Partner (霞鹜溪黑搭档), a Chinese sans-serif font";
    homepage = "https://github.com/lxgw/XiHeiPartner";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
