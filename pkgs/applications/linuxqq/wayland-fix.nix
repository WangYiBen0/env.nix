{
  lib,
  stdenv,
  bash,
  fetchFromGitHub,
  pkg-config,
  wayland-scanner,
  makeWrapper,
  libx11,
  glib,
  wayland,
  libpulseaudio,
  pipewire,
  procps,
  wayland-utils,
  systemd,
}:

# Just the payload of SHORiN-KiWATA/linuxqq-wayland-fix: the three LD_PRELOAD
# libraries injected into QQ, plus the upstream launcher/diagnostic script.
# ../package.nix (pkgs.linuxqq) is the drop-in replacement for pkgs.qq that
# actually wires these into QQ; this derivation stays separate so the injected
# code is built and attributed on its own.
stdenv.mkDerivation (finalAttrs: {
  pname = "linuxqq-wayland-fix";
  version = "0.2.2";

  src = fetchFromGitHub {
    owner = "SHORiN-KiWATA";
    repo = "linuxqq-wayland-fix";
    rev = "v${finalAttrs.version}";
    hash = "sha256-eL0UXdDCjzEbfOnkLH0kQQ8Yeoq2kYErHQaVDJmX5d8=";
  };

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    makeWrapper
  ];

  # libpulseaudio and pipewire are only needed for their headers: the injected
  # libraries never link against them (upstream's Makefile only asks pkg-config
  # for `gio-unix-2.0`, `x11` and `wayland-client` at link time).
  buildInputs = [
    glib
    libx11
    wayland
    libpulseaudio
    pipewire
  ];

  strictDeps = true;

  enableParallelBuilding = true;

  doCheck = false;

  # The upstream Makefile bakes the absolute library directory into the
  # launcher script (`@LIBEXECDIR@` -> `LIBDIR`) via `sed`, and `$out` is only
  # known inside the sandbox.  Exporting these from bash -- rather than via
  # `env`, `makeFlags` or `installFlags` -- keeps `$out` a *shell* expansion;
  # the attribute-based variants get shell-escaped and make would then read
  # `$o` as a make variable, silently installing into `ut/`.
  installPhase = ''
    runHook preInstall

    export PREFIX="$out"
    export LIBEXECDIR="$out/lib/${finalAttrs.pname}"
    export VERSION="${finalAttrs.version}"

    # `buildPhase` already generated the launcher with the upstream `/usr`
    # defaults, so drop it to force make to re-run the `sed` substitution
    # with the final store paths above.
    rm -f linuxqq-wayland-fix

    make install

    # The launcher ships a `#!/bin/bash` shebang.  `patchShebangs` does not
    # rewrite it once wrapProgram has moved the script aside, and `/bin/bash`
    # does not exist in a Nix store, so point it at the stdenv bash explicitly.
    substituteInPlace "$out/bin/${finalAttrs.pname}" \
      --replace '#!/bin/bash' "#!${bash}/bin/bash"

    runHook postInstall
  '';

  # `linuxqq-wayland-fix --doctor` shells out to a few runtime tools; they are
  # not needed for the LD_PRELOAD injection itself, but shipping them keeps the
  # self-check usable.
  postFixup = ''
    wrapProgram $out/bin/${finalAttrs.pname} \
      --prefix PATH : ${
        lib.makeBinPath [
          procps
          wayland-utils
          systemd
        ]
      }
  '';

  meta = {
    description = "LD_PRELOAD libraries fixing Linux QQ screen sharing, shared audio, clipboard and screenshot crashes on Wayland";
    homepage = "https://github.com/SHORiN-KiWATA/linuxqq-wayland-fix";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = finalAttrs.pname;
  };
})
