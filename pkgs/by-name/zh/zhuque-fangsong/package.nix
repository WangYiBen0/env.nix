{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "zhuque-fangsong";
  version = "0.212";

  src = fetchzip {
    url = "https://github.com/TrionesType/zhuque/releases/download/v${finalAttrs.version}/ZhuqueFangsong-v${finalAttrs.version}.zip";
    hash = "sha256-see78H4ClZON4pujyUxvCjphFrKG73qBVEyhRoSxZ0Y=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 $src/ZhuqueFangsong-Regular.ttf $out/share/fonts/truetype/ZhuqueFangsong-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    # Every upstream release is marked as a prerelease ("technical preview"),
    # so the default stable strategy always raises VersionError; track the
    # newest release explicitly.
    extraArgs = [
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "An open-source Fangsong typeface project";
    homepage = "https://github.com/TrionesType/zhuque";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
