{
  lib,
  stdenvNoCC,
  fetchurl,
  nix-update-script,
}:

let
  # honk's native API (the contract doona speaks) only exists on honk's
  # `feat/native-api` branch, which upstream has not released yet. Until it
  # ships a tagged release, doona's own releases attach matching honk builds,
  # and `HONK-SOURCE.txt` in the same release records the honk tag, commit and
  # SHA-256 of every asset. Those are the binaries we pin.
  #
  # Tracked source: https://github.com/daeuniverse/honk/tree/5e726a9c0c98864d05550c235b326cad83abc006
  doonaVersion = "0.1.0-beta.14";
  honkBuild = "debug.2026.10.4.native-api.2";

  # The musl builds are statically linked, so they need no glibc/allocator
  # matching at all.
  hostSystem = stdenvNoCC.hostPlatform.system;
  target =
    {
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
    }
    .${hostSystem} or (throw "honk is not packaged for ${hostSystem}");

  # Top-level directory inside the release archive.
  prefix = "honk-core-debug-${target}";
in
stdenvNoCC.mkDerivation {
  pname = "honk";
  version = honkBuild;

  src = fetchurl {
    url = "https://github.com/Zakkaus/doona/releases/download/v${doonaVersion}/honk-core-debug-${target}.tar.gz";
    hash =
      {
        "x86_64-unknown-linux-musl" = "sha256-6JT7ZnQhKYT75oWaFuUKRryS80sXxayhX+G0z6NdCgY=";
        "aarch64-unknown-linux-musl" = "sha256-IQakPTJL0LMo6D3JNhRY1Hpat9Ju0aHo1F9JbynZ/WU=";
      }
      .${target};
  };

  dontUnpack = true;
  dontBuild = true;
  dontConfigure = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/licenses/honk
    # --strip-components applies after member-name matching, so name the
    # archive's top-level directory exactly rather than globbing: a '*'
    # also matches '/', which would drag in the bundled doona/ tree.
    tar -xzf "$src" --strip-components=1 -C $out/bin "${prefix}/honk-core"
    tar -xzf "$src" --strip-components=1 -C $out/share/licenses/honk "${prefix}/LICENSE"
    chmod 0755 $out/bin/honk-core

    runHook postInstall
  '';

  # doona re-tags honk's own rolling `debug` pre-release, so the tag moves
  # every time doona publishes. Only the per-version tag under the doona
  # repository is stable, and the asset name already carries it.
  passthru.updateScript = nix-update-script { };

  meta = {
    description = "eBPF transparent proxy engine with the daeuniverse native API";
    homepage = "https://github.com/daeuniverse/honk";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "honk-core";
  };
}
