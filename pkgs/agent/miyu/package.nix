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
  version = "0.4.5";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-PEyVg0SEPKf85E14EusgGmNIYOcr5KXOuS9e9QftlPo=";
  };

  cargoHash = "sha256-SBl+JcmKEonUmmFt1Zpf+2TeAhFlvRktd2IJxKHraU4=";

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
