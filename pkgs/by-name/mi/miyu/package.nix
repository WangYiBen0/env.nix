{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
  pkg-config,
  alsa-lib,
  openssl,
  sqlite,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "miyu";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-uPbRqorYXqIpnQEClGPA1G0loTqnmKXpV5EpHSVtJQo=";
  };

  cargoHash = "sha256-Ym60PGS4FEvtOGtEYXfjeQrmLb0RZMn22ZD8mkv/Vkg=";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    alsa-lib
    openssl
    sqlite
  ];

  # The test suite expects to reach live LLM endpoints.
  doCheck = false;

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Command-line AI assistant with TUI diff display";
    homepage = "https://github.com/SHORiN-KiWATA/Miyu";
    license = licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "miyu";
  };
})
