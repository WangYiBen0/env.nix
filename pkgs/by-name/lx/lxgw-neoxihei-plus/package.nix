{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "lxgw-neoxihei-plus";
  version = "1.309";

  src = fetchurl {
    url = "https://github.com/lxgw/LxgwNeoXiHei/releases/download/v${finalAttrs.version}/LXGWNeoXiHeiPlus.ttf";
    hash = "sha256-ho1Te75+qDo1okn8qClynq2TN4KODEcJ8pviJ3wRckM=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 $src $out/share/fonts/truetype/LXGWNeoXiHeiPlus.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    # nixpkgs ships the plain LXGW Neo XiHei; this one is the "+" build, whose
    # glyph set fills in CJK Extension A so the coverage reaches GB 18030-2022
    # implementation level 2. Same family look, more characters.
    description = "LXGW Neo XiHei Plus (霞鹜新晰黑＋), a Chinese sans-serif with CJK Extension A filled in";
    homepage = "https://github.com/lxgw/LxgwNeoXiHei";
    license = lib.licenses.ipa;
    platforms = lib.platforms.all;
  };
})
