{
  lib,
  stdenv,
  fetchgit,
  love,
  makeWrapper,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "loenn";
  version = "1.0.10";

  src = fetchgit {
    url = "https://github.com/CelestialCartographers/Loenn.git";
    rev = "v${finalAttrs.version}";
    fetchSubmodules = true;
    hash = "sha256-rc3yH5LNNSWIJceIZ95UUner9hqrlkGtdHScYu3ZUuU=";
  };

  dontBuild = true;
  dontConfigure = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/loenn $out/bin
    cp -r $src/src/* $out/lib/loenn/

    makeWrapper ${love}/bin/love $out/bin/loenn \
      --argv0 loenn \
      --add-flags "$out/lib/loenn"

    runHook postInstall
  '';

  meta = {
    description = "Lönn - A visual level maker and editor for the game Celeste";
    homepage = "https://github.com/CelestialCartographers/Loenn";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "loenn";
  };
})
