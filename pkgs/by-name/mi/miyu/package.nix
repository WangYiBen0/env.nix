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
  version = "0.7.4";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-l6bxYQeQivgleCagk2WQg9P5exVJv73e0C3v2JQTztA=";
  };

  cargoHash = "sha256-cEjBtE10L+wEi6yAaPnIDZ8+Fa5nRxJk9YQpF02AVWE=";

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
