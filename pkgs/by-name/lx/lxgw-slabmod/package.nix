{
  lib,
  fetchzip,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW SlabMod (霞鹜楷体SlabMod), a Chinese serif font
#   * Archived upstream repo; built from git snapshot @ 1915e6c
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-slabmod";
  version = "1915e6c08e535c4ef4b1e9cda70a704c730c9a9e";

  src = fetchzip {
    url = "https://github.com/lxgw/SlabMod/archive/${finalAttrs.version}.tar.gz";
    hash = "sha256-tkFxxvLYemx625bJ/AvLXBhe2RjhZfZ/scet4kZQv4I=";
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
    description = "LXGW SlabMod (霞鹜楷体SlabMod), a Chinese serif font";
    homepage = "https://github.com/lxgw/SlabMod";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
