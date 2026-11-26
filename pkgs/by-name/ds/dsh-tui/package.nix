{
  lib,
  stdenv,
  bubblewrap,
  fetchurl,
  makeBinaryWrapper,
  nix-update-script,
  nodejs_24,
  pnpm_11,
}:

# Upstream packaging contract:
#   * dsh-TUI is published to npm, but bin/dsh-tui.js — the only file the
#     store copy ever executes — is a hand-written source file in the
#     repository, byte-identical to the one in the npm tarball. Building from
#     the git tag keeps the packaging honest (the artifact comes from the
#     reviewed repository, not from a registry CDN) and drops the fetchzip
#     unpack step.
#   * The store copy is a *launcher*: it looks for a profile copy under
#     $DSH_HOME/profiles/dsh-tui, delegates to it when present, and otherwise
#     bootstraps it with `dsh plugin --profile dsh-tui add <this package>`,
#     which installs the full dependency tree itself. So nothing here needs
#     npm dependencies resolved, and pnpm/node/nodejs are runtime inputs of
#     the wrapper rather than build inputs of a frontend build.
#   * package.json and guide/ are read at runtime (the launcher reports its
#     own version from package.json), so they are installed alongside bin/.
stdenv.mkDerivation (finalAttrs: {
  pname = "dsh-tui";
  version = "0.20.2";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchurl {
    url = "https://github.com/ccch1mneyyy/dsh-TUI/archive/v${finalAttrs.version}.tar.gz";
    hash = "sha256-4n5WgJjRVejYNbscATZfS2U8tEQkrSm7IbHMbBhjIDk=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    nodejs_24
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 bin/dsh-tui.js $out/libexec/dsh-tui/bin/dsh-tui.js
    install -Dm644 package.json $out/libexec/dsh-tui/package.json

    # The launcher resolves the guide relative to its own package root.
    cp -r guide $out/libexec/dsh-tui/guide

    makeBinaryWrapper ${nodejs_24}/bin/node $out/bin/dsh-tui \
      --add-flags "$out/libexec/dsh-tui/bin/dsh-tui.js" \
      --prefix PATH : ${
        lib.makeBinPath [
          bubblewrap
          nodejs_24
          pnpm_11
        ]
      }

    # Upstream also advertises `dst` as an alias bin entry.
    ln -s dsh-tui $out/bin/dst

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/dsh-tui help >/dev/null
    $out/bin/dst help >/dev/null
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Terminal UI launcher for DeepSeek Harness";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = licenses.mit;
    mainProgram = "dsh-tui";
    platforms = platforms.linux;
  };
})
