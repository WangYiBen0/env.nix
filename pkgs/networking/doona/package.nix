{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
  withFonts ? true,
  withPrecompressed ? true,
}:

let
  version = "0.1.0-beta.14";

  # doona is a prebuilt static web UI: honk serves whatever directory
  # `experimental.native_api.ui` points at, so these are installed
  # unpacked and unstripped. Lazily fetched, so `withFonts = false`
  # and `withPrecompressed = false` never hit the network.
  fonts = fetchurl {
    url = "https://github.com/Zakkaus/doona/releases/download/v${version}/doona-fonts-${version}.tar.gz";
    hash = "sha256-IfqWbBZdFOC9+uCn5qFWZyZvqWjr7S3j42jauCu+LTk=";
  };

  precompressed = fetchurl {
    url = "https://github.com/Zakkaus/doona/releases/download/v${version}/doona-precompressed-${version}.tar.gz";
    hash = "sha256-EMiFsvZQCtegg05LGAiqaj/uqu8lorgKd4bHj9Z5rL4=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "doona";
  inherit version;

  src = fetchurl {
    url = "https://github.com/Zakkaus/doona/releases/download/v${finalAttrs.version}/doona-${finalAttrs.version}.tar.gz";
    hash = "sha256-cCIngmEbi5orNyTXw0+qn7K/dnhsDcoyId3V8YxCMyg=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/doona
    tar -xzf "$src" -C $out/share/doona
  ''
  + lib.optionalString withFonts ''
    tar -xzf ${fonts} -C $out/share/doona
  ''
  + lib.optionalString withPrecompressed ''
    tar -xzf ${precompressed} -C $out/share/doona
  ''
  + ''

    test -f $out/share/doona/index.html || {
      echo "doona: index.html missing from the release archive" >&2
      exit 1
    }

    runHook postInstall
  '';

  passthru.updateScript = nix-update-script { };

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
