{
  lib,
  buildNpmPackage,
  fetchzip,
  makeWrapper,
  nodejs,
  pnpm,
}:

buildNpmPackage (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.1.1-rc.2";

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${finalAttrs.version}.tgz";
    hash = "sha256-lmml3QdvbjNCPbY7NBEjQt86lRJiTn5I2fy7CwL6PdY=";
  };

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
    chmod u+w package-lock.json
    if command -v node >/dev/null; then
      node -e "
        const fs = require('fs');
        const pkg = JSON.parse(fs.readFileSync('package.json'));
        delete pkg.devDependencies;
        fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
      "
    fi
  '';

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    rm $out/bin/dsh
    makeWrapper ${nodejs}/bin/node $out/bin/dsh \
      --add-flags "--expose-internals" \
      --add-flags "$out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js" \
      --suffix PATH : ${lib.makeBinPath [ pnpm ]} \
      --suffix PATH : $out/bin
    for f in $out/lib/node_modules/@deepseek-ai/dsh/node_modules/node-pty/prebuilds/*/spawn-helper; do
      [ -f "$f" ] && chmod +x "$f"
    done
  '';

  npmDepsFetcherVersion = 2;
  npmDepsHash = "sha256-biS8nDzUUYhIl6mH52UmgTSg9QcLFPwLc/B3dk5clh4=";

  passthru = {
    packageName = "@deepseek-ai/dsh";
    updateScript = [
      ./update.sh
    ];
  };

  meta = with lib; {
    description = "Open-source agent harness developed by DeepSeek AI, everything is a plugin";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = licenses.mit;
    mainProgram = "dsh";
  };
})
