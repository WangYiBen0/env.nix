{
  lib,
  stdenv,
  bubblewrap,
  fetchzip,
  makeBinaryWrapper,
  nodejs_24,
  pnpm_11,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dsh-tui";
  version = "0.11.0";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-harness-tui/dsh-tui/-/dsh-tui-${finalAttrs.version}.tgz";
    hash = "sha256-3jeYWrtrPDnSEe4+Qp/C3x9A70YTfb8yI7x1SN3SJDA=";
  };

  # The published tarball is a launcher plus a TUI that gets installed into the
  # dsh profile by `dsh plugin add` on first run, which brings its own
  # dependency tree. The store copy only ever executes bin/dsh-tui.js, which
  # upstream keeps free of lib/ imports, so no npm dependencies are fetched or
  # installed here.
  nativeBuildInputs = [
    makeBinaryWrapper
    nodejs_24
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/dsh-tui/bin
    install -m644 bin/dsh-tui.js $out/libexec/dsh-tui/bin/dsh-tui.js
    install -m644 package.json $out/libexec/dsh-tui/package.json

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

  meta = with lib; {
    description = "Terminal UI launcher for DeepSeek Harness";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = licenses.mit;
    mainProgram = "dsh-tui";
    platforms = platforms.linux;
  };
})
