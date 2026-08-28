{
  lib,
  buildNpmPackage,
  fetchzip,
  makeWrapper,
  nodejs,
  pnpm,
  bash,
}:

let
  runtimePath = lib.makeBinPath [
    bash
    nodejs
    pnpm
  ];
in
buildNpmPackage (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.1.1-rc.2";

  src = fetchzip {
    url = "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-${finalAttrs.version}.tgz";
    hash = "sha256-lmml3QdvbjNCPbY7NBEjQt86lRJiTn5I2fy7CwL6PdY=";
  };

  # NixOS does not provide the terminal backend's default /bin/bash. Point the
  # PTY shell at the Nix-provided bash so the Bash tool can spawn a shell.
  patches = [ ./use-nix-bash.patch ];

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
    substituteInPlace config/agent-presets/minimal/agent.cordis.yml \
      --replace-fail "@bash@" "${lib.getExe bash}"
  '';

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    rm $out/bin/dsh
    makeWrapper ${nodejs}/bin/node $out/bin/dsh \
      --add-flags "--expose-internals" \
      --add-flags "$out/lib/node_modules/@deepseek-ai/dsh/lib/bin.js" \
      --prefix PATH : ${runtimePath} \
      --suffix PATH : $out/bin

    # Drop node-pty prebuilds for foreign platforms so the PTY backend only
    # resolves the native addon for the host OS.
    nodePtyPrebuilds="$out/lib/node_modules/@deepseek-ai/dsh/node_modules/node-pty/prebuilds"
    if [ -d "$nodePtyPrebuilds" ]; then
      find "$nodePtyPrebuilds" -mindepth 1 -maxdepth 1 -type d \
        \( -name 'darwin-*' -o -name 'win32-*' \) -exec rm -rf {} +
    fi

    # dsh-terminal-bash hardcodes /bin/bash as the default shell; on NixOS that
    # path does not exist. Rewrite the fallback so any preset or profile that
    # does not set an explicit shellPath still resolves a usable bash.
    find "$out/lib/node_modules/@deepseek-ai/dsh/node_modules/@deepseek-ai/dsh-terminal-bash" \
      -path "*/lib/index.js" -exec \
      sed -i 's#const DEFAULT_BASH_SHELL = "/bin/bash";#const DEFAULT_BASH_SHELL = "${lib.getExe bash}";#' {} +
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
    platforms = platforms.linux;
  };
})
