{
  lib,
  stdenv,
  bubblewrap,
  fetchzip,
  makeBinaryWrapper,
  nix-update-script,
  nodejs_24,
  pnpm_11,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "dsh-tui";
  version = "0.15.0";

  strictDeps = true;
  __structuredAttrs = true;

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-harness-tui/dsh-tui/-/dsh-tui-${finalAttrs.version}.tgz";
    hash = "sha256-VZW9fHvVUVvSVXx1giiyuFqsc57YNW3vkCFuyttKHn4=";
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

    install -Dm644 bin/dsh-tui.js $out/libexec/dsh-tui/bin/dsh-tui.js
    install -Dm644 package.json $out/libexec/dsh-tui/package.json

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

  passthru.updateScript = nix-update-script {
    # The update script re-invokes nix-update without --flake, which cannot
    # eval this flake; always point it back at the local flake.
    extraArgs = [ "--flake" ];
  };

  meta = with lib; {
    description = "Terminal UI launcher for DeepSeek Harness";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = licenses.mit;
    mainProgram = "dsh-tui";
    platforms = platforms.linux;
  };
})
