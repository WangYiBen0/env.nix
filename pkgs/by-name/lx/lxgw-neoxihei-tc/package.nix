{
  lib,
  fetchzip,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Neo XiHei TC (霞鹜新溪黑繁体), Traditional Chinese variant of Neo XiHei
#   * Archived upstream repo; built from git snapshot @ 112abc7
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neo-xi-hei-tc";
  version = "112abc746c58999fa929751b4759438520366e5f";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwNeoXiHeiTC/archive/${finalAttrs.version}.tar.gz";
    hash = "sha256-v3WoNhDgn/4tuq3UrM+/1iugUBrvs3/5fKjTmT5K1M4=";
  };

  dontUnpack = false;

  nativeBuildInputs = [ ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/truetype

    find $src -name '*.ttf' -exec install -m644 {} $out/share/fonts/truetype/ \;

    runHook postInstall
  '';

  # No passthru.updateScript: upstream publishes no tags for this repository
  # (git ls-remote --tags returns nothing), so the version is a pinned commit
  # hash and nix-update's release-feed detection has nothing to read. Adding
  # the script back makes every bot run fail for this package.

  meta = {
    description = "LXGW Neo XiHei TC (霞鹜新溪黑繁体), Traditional Chinese variant of Neo XiHei";
    homepage = "https://github.com/lxgw/LxgwNeoXiHeiTC";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
