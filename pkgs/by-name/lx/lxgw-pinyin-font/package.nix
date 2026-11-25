{
  lib,
  fetchzip,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * LXGW Pinyin Font (霞鹜拼音字体), a Chinese font for pinyin annotation
#   * Archived upstream repo; built from git snapshot @ 89a9cd5
#   * TTF file(s) installed: matching *.ttf from source root

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-pinyin-font";
  version = "89a9cd51c440d9e02d9d9896a7f30e1bc8db1530";

  src = fetchzip {
    url = "https://github.com/lxgw/LxgwPinyinFont/archive/${finalAttrs.version}.tar.gz";
    hash = "sha256-zO1G9IctoMdNZdeF1iUMKrYuhSzxULLd2r7pvrFmBVo=";
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
    description = "LXGW Pinyin Font (霞鹜拼音字体), a Chinese font for pinyin annotation";
    homepage = "https://github.com/lxgw/LxgwPinyinFont";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
