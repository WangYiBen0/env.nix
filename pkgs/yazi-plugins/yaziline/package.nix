{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
}:
stdenvNoCC.mkDerivation {
  pname = "yaziline.yazi";
  version = "2.5.6";

  src = fetchFromGitHub {
    owner = "llanosrocas";
    repo = "yaziline.yazi";
    rev = "029b27d55361b4b87d0982237f9730b49b4e7a3a";
    sha256 = "0rgzaaadgv14k7j9147qwm2r26hw5cbc09x8bky7ki5m122dp2x1";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp $src/main.lua $out/
  '';

  meta = {
    description = "Simple lualine-like status line for yazi";
    homepage = "https://github.com/llanosrocas/yaziline.yazi";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
  };
}
