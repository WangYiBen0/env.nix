{
  lib,
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  alsa-lib,
  openssl,
  sqlite,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "miyu";
  version = "0.4.0";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-iKAMx6V49C3eHPqgZ6h+xfde/6+Ka8we0iQb9rmfCbo=";
  };

  cargoHash = "sha256-Lve7ScQsV2VlXy4S/yrMFhr+hMmr5Yv73DT4Gnr3dG8=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    alsa-lib
    openssl
    sqlite
  ];

  doCheck = false;

  meta = with lib; {
    description = "Command-line AI assistant with TUI diff display";
    homepage = "https://github.com/SHORiN-KiWATA/Miyu";
    license = licenses.mit;
    mainProgram = "miyu";
  };
})
