{
  lib,
  stdenvNoCC,
  brotli,
  fetchFromGitHub,
  fetchPnpmDeps,
  nodejs_24,
  nodejs-slim_24,
  nix-update-script,
  pnpm_11,
  pnpmConfigHook,
  withFonts ? true,
  withPrecompressed ? true,
}:

let
  version = "0.1.0-rc.4";

  # pnpm-workspace.yaml carries `allowBuilds`, so only esbuild's postinstall
  # is permitted; playwright's browser download never runs. Upstream pins
  # pnpm@11.15.1 — any 11.x reads the same lockfileVersion 9.0.
  pnpm = pnpm_11.override { nodejs-slim = nodejs-slim_24; };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "doona";
  inherit version;

  src = fetchFromGitHub {
    owner = "Zakkaus";
    repo = "doona";
    tag = "v${finalAttrs.version}";
    hash = "sha256-mGcbB8sEvTNrek+30c5d8oy7p4LTX0EB2WS2TuMEXM8=";
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    inherit pnpm;
    fetcherVersion = 4;
    hash = "sha256-N4Goi5+BddeW0C+NA+h0Ae2U9RWbVCmpliExQjySlUc=";
  };

  nativeBuildInputs = [
    brotli
    nodejs_24
    pnpm
    pnpmConfigHook
  ];

  # The default buildPhase would run `make`, whose first target is `deps` and
  # so only installs. Build the UI explicitly.
  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  # honk serves whatever directory `experimental.native_api.ui` names, so the
  # tree is installed to /share/doona exactly as upstream's tools/package.sh
  # stages it, minus the tarball. That script shells out to `git log` for
  # SOURCE_DATE_EPOCH and only needs it to stamp tar members, which Nix
  # normalises anyway; the compression and layout rules are reproduced here.
  # The order matters: package.sh compresses dist/ before adding the licence
  # files, so only assets Vite emitted ever gain a precompressed sibling.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/doona

    # Everything in dist/ but the fonts and the Vite metadata directory, which
    # upstream does not ship either. It still matters: the manifest inside it
    # is what notices.mjs reads below, straight out of the build directory.
    for entry in dist/* dist/.[!.]* dist/..?*; do
      [ -e "$entry" ] || [ -L "$entry" ] || continue
      [ "$entry" != dist/fonts ] || continue
      [ "$entry" != dist/.vite ] || continue
      cp -R "$entry" $out/share/doona/
    done
  ''
  + lib.optionalString withPrecompressed ''
    # Precompressed siblings, exactly as tools/package.sh makes them: brotli
    # quality 11 and gzip -9 with no embedded timestamp, kept only when the
    # result beats the original. honk's ServeDir is told to look for .br and
    # .gz and serves them in place of the original when the client allows,
    # so the encoding work moves off the request path.
    find $out/share/doona -type f -size +1023c \( \
        -name '*.js' -o -name '*.css' -o -name '*.html' -o -name '*.svg' -o \
        -name '*.json' -o -name '*.webmanifest' -o -name '*.txt' -o -name '*.map' \
      \) -print0 |
      xargs -0 -r sh -ec '
        for asset do
          size=$(wc -c < "$asset")
          brotli -q 11 -c < "$asset" > "$asset.br"
          [ "$(wc -c < "$asset.br")" -lt "$size" ] || rm -f "$asset.br"
          gzip -9 -n -c < "$asset" > "$asset.gz"
          [ "$(wc -c < "$asset.gz")" -lt "$size" ] || rm -f "$asset.gz"
        done
      ' sh
  ''
  + ''
    cp LICENSE NOTICE README.md $out/share/doona/
    # 0.1.0-rc.2 added a second argument: the bundled-package manifest Vite
    # writes to dist/.vite/. Called with only the stage, the script prints its
    # usage and exits 1 — which is exactly what failed the closure build on the
    # bot's bump. Mirrors upstream's `add_notices "$stage/program" dist`.
    node tools/notices.mjs $out/share/doona dist/.vite/bundled-packages.json
  ''
  + lib.optionalString withFonts ''
    cp -R dist/fonts $out/share/doona/fonts
  ''
  + ''

    test -f $out/share/doona/index.html || {
      echo "doona: index.html missing from the build" >&2
      exit 1
    }

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script {
    # TODO: Drop after 1.0
    extraArgs = [
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "Web UI for the daeuniverse engines (honk), served at /ui/";
    homepage = "https://github.com/Zakkaus/doona";
    # lib.licenses has no entry for the GitHub logo terms that
    # LICENSES/LicenseRef-GitHub-Logos.txt carries.
    license =
      with lib.licenses;
      [
        gpl3Only
        bsd0
        asl20
        bsd3
        isc
        mit
        cc-by-30
        cc-by-40
        cc-by-sa-40
        cc0
      ]
      ++ lib.optional withFonts ofl;
    platforms = lib.platforms.unix;
  };
})
