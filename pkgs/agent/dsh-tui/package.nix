{
  lib,
  buildNpmPackage,
  fetchzip,
  makeWrapper,
  nodejs,
  pnpm,
}:

buildNpmPackage (finalAttrs: {
  pname = "dsh-tui";
  version = "0.9.0";

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-harness-tui/dsh-tui/-/dsh-tui-${finalAttrs.version}.tgz";
    hash = "sha256-qD2y9sMx72LzQOXior+zfLRDh4pu3gAzA3edlQE0AGA=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    chmod u+w package-lock.json
    if command -v node >/dev/null; then
      node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json'));
        delete pkg.devDependencies;
        delete pkg.peerDependencies;
        delete pkg.optionalDependencies;
        delete pkg.scripts;
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
      "
    fi
  '';

  dontNpmBuild = true;
  npmFlags = [ "--legacy-peer-deps" ];

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    rm $out/bin/dsh-tui
    makeWrapper ${nodejs}/bin/node $out/bin/dsh-tui \
      --add-flags "$out/lib/node_modules/@deepseek-harness-tui/dsh-tui/bin/dsh-tui.js" \
      --prefix PATH : ${
        lib.makeBinPath [
          nodejs
          pnpm
        ]
      }
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-pswXCcBb26XhrcuW1jEZbADFWe5oQ+M/WbGf2tkIqKU=";

  passthru.updateScript = ./update.sh;

  meta = with lib; {
    description = "Terminal UI launcher for DeepSeek Harness";
    homepage = "https://github.com/ccch1mneyyy/dsh-TUI";
    license = licenses.mit;
    mainProgram = "dsh-tui";
    platforms = platforms.linux;
  };
})
