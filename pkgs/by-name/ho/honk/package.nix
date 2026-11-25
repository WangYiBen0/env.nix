{
  lib,
  fetchurl,
  nix-update-script,
  stdenvNoCC,
}:

# Upstream packaging contract:
#   * daeuniverse/honk ships prebuilt tarballs on its tags; the newest tag is
#     v0.1.0-beta.6 and there is no 1.0 yet.  Each asset is
#     honk-core-v<version>-<target>-<variant>.tar.gz and unpacks to a single
#     top-level directory holding honk-core, LICENSE, README.md and, for the
#     "full" variant, the doona/ and doona-lite/ notice trees of the UI it
#     embeds.
#   * The musl "full" asset is installed: statically linked, so there is no
#     interpreter to patch, no libc/libstdc++ to match, and nothing for
#     patchelf to do.  Its feature set is the one the NixOS module needs —
#     ebpf, rprx, clash-api, native-ui (which pulls in native-api) and
#     jemalloc.
#   * Only the x86_64 asset is pinned, and meta.platforms says so: this
#     repository has no aarch64-linux host, and nix-update refreshes the one
#     hash it finds, so a second architecture would silently rot.
#   * The web UI is served from disk, not from the embedded copy: the module
#     points experimental.native_api.ui at pkgs.doona, and the binary only
#     picks its built-in assets for the literal paths "embedded" and
#     "embedded-lite" (crates/honk-core/src/native_api/ui.rs).
#
# This package used to build from source — a pinned nightly toolchain for the
# eBPF object, three Cargo.lock files, a bpf-linker override and a hand-written
# update script — while upstream was publishing exactly these binaries.  The
# eBPF/LLVM pinning is upstream CI's problem now, and the whole update path
# is a tag lookup plus one hash.

let
  # Both segments of the asset name are fixed by the release workflow.
  target = "x86_64-unknown-linux-musl";
  variant = "full";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "honk";
  version = "0.1.0-beta.7";

  src = fetchurl {
    url = "https://github.com/daeuniverse/honk/releases/download/v${finalAttrs.version}/honk-core-v${finalAttrs.version}-${target}-${variant}.tar.gz";
    hash = "sha256-nz0iSo3OOPfhUcYUB6tu3bPHoYJ18T6zdDMCsaEgxmw=";
  };

  dontConfigure = true;
  dontBuild = true;
  dontUnpack = true;
  # The binary is already stripped and statically linked: fixup's stripping and
  # patchelf passes have nothing to act on, and patchelf on a file without a
  # dynamic section only risks rewriting it.
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    # --strip-components applies after member-name matching, so name the
    # archive's top-level directory exactly instead of globbing: a '*' also
    # matches '/', which would drag in the bundled doona/ tree.
    prefix="honk-core-v${finalAttrs.version}-${target}-${variant}"

    mkdir -p $out/bin $out/share/licenses/honk
    tar -xzf "$src" --strip-components=1 -C $out/bin "$prefix/honk-core"
    chmod 0755 $out/bin/honk-core

    # The binary embeds the doona UI, so the notices the full archive ships
    # for it are redistributed alongside.
    tar -xzf "$src" --strip-components=1 -C $out/share/licenses/honk \
      "$prefix/LICENSE" "$prefix/doona" "$prefix/doona-lite"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/honk-core" --version
    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script {
    extraArgs = [
      # releases.atom lists rolling debug tags ("Debug", "debug.2026.10.21.1",
      # "debug-diag.issue-415.3") next to the versioned ones, and those sort
      # *above* every v0.1.0-beta.N, because a numeric segment outranks an
      # alpha one. The regex keeps versioned tags only and drops the leading
      # "v" from the package version. Widen or delete it once a 1.0 tag exists.
      "--version-regex"
      "v?([0-9.]+(?:-[a-z]+\\.[0-9.]+)*)"
      # Every published tag so far is a pre-release, which nix-update refuses
      # by default ("Found an unstable version ...").
      "--version"
      "unstable"
    ];
  };

  meta = {
    description = "eBPF transparent proxy engine with the doona native API";
    homepage = "https://github.com/daeuniverse/honk";
    changelog = "https://github.com/daeuniverse/honk/releases";
    license = lib.licenses.gpl3Only;
    # Repackaged prebuilt binary: these are the assets upstream tests and
    # supports, and rebuilding the eBPF object needs the nightly toolchain
    # that only their CI pins.
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "honk-core";
  };
})
