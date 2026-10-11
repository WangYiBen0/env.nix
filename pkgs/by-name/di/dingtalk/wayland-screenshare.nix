{
  fetchFromGitHub,
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  libsForQt5,
  libportal,
  pipewire,
  opencv,
  libx11,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  libxtst,
}:
let
  pname = "dingtalk-wayland-screenshare";
  # Untagged upstream commit; bump `rev` together with its date-based
  # version below (nix-update cannot track this repository).
  rev = "e15063310eb3251e4619345c8fad0059e8a0558a";
  version = "0-unstable-2025-03-21";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "lzl200110";
    repo = "dingtalk-wayland-screenshare";
    inherit rev;
    fetchSubmodules = true;
    hash = "sha256-yCTb1gy6gzy1WzcetrRAsoG77ST1yf+zKtTD3fojKRw=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libsForQt5.qtbase
    libsForQt5.qtx11extras
    libportal
    pipewire
    opencv
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxtst
  ];

  dontWrapQtApps = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 libdingtalkhook.so $out/lib/libdingtalkhook.so

    runHook postInstall
  '';

  meta = {
    description = "DingTalk screen sharing implementation under Wayland";
    homepage = "https://github.com/lzl200110/dingtalk-wayland-screenshare";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
