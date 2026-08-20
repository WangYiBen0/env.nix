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
  version = "0.4.4";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "Miyu";
    rev = "v${finalAttrs.version}";
    hash = "sha256-YYYfXdP0g9jikPP15Pe65H/I0kKTmtfCmdZgUxGC5hs=";
  };

  cargoHash = "sha256-D9OwqnzTrVuEUw7H5EFd7XvopygRrk7KXm/tEsQb8TA=";

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
