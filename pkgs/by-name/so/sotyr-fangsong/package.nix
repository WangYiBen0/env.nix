{
  lib,
  fetchzip,
  nix-update-script,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "sotyr-fangsong";
  version = "0.23-beta";

  # The font is only published inside the source archive: no release asset, and
  # the repository build scripts need fontforge, so take the built TTF that is
  # checked in under fonts/.
  src = fetchzip {
    url = "https://github.com/Hulenkius/sotyr/archive/refs/tags/v${finalAttrs.version}.tar.gz";
    hash = "sha256-PU7jZ8Hb/74jOpA9vz6faSwuCJjQAlxn0waRslYSx08=";
  };

  installPhase = ''
    runHook preInstall

    install -Dm644 $src/fonts/SotyrFangsong-Regular.ttf $out/share/fonts/truetype/SotyrFangsong-Regular.ttf

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    # Every tag is a -beta pre-release, so the default stable strategy finds
    # nothing to update to.
    extraArgs = [
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "Sotyr Fangsong (仲春仿宋), a digital revival of the Juzhen Fangsong No. 2 type";
    longDescription = ''
      A direct re-carving of the 聚珍仿宋二号长体 lead type: glyphs are
      extracted from scans of period printing and packed as a font, rather than
      redrawn by hand. Traditional characters only at this stage, and it is
      still a pre-release — good for classical text, not for modern simplified
      copy.
    '';
    homepage = "https://github.com/Hulenkius/sotyr";
    license = lib.licenses.ofl;
    platforms = lib.platforms.all;
  };
})
