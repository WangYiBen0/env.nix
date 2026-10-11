{
  lib,
  callPackage,
  writeText,
  # Upstream Tencent QQ as packaged by nixpkgs.  `callPackage` resolves this to
  # `pkgs.qq`; we inject the Wayland fixes into it so `pkgs.linuxqq` is the
  # single package a consumer installs and the stock QQ is never installed
  # alongside it.
  qq,
}:

let
  # The three LD_PRELOAD libraries plus the upstream launcher/diagnostic script
  # (see ./wayland-fix.nix for why this is its own derivation).
  waylandFix = callPackage ./wayland-fix.nix { };

  fixLibDir = "${waylandFix}/lib/${waylandFix.pname}";
  fixLibs = map (lib: "${fixLibDir}/${lib}") [
    "libqq-wl-portal.so"
    "libqq-clipbridge.so"
    "libqq-screenshot.so"
  ];
  fixPreload = lib.concatStringsSep ":" fixLibs;

  # The three export lines, emitted verbatim into the stock QQ wrapper.
  # `LD_PRELOAD` is *prepended* to whatever the stock wrapper has already set
  # (libssh2), so nothing upstream provides is lost.
  injection = ''
    LD_PRELOAD="${fixPreload}:''${LD_PRELOAD:+:''$LD_PRELOAD}"
    export LD_PRELOAD
    export XDG_SESSION_TYPE=x11
    export MESA_SHADER_CACHE_DISABLE=true
  '';
in

# Reuse nixpkgs' QQ wrapper -- it already execs `$out/opt/QQ/qq` and sets up
# XDG_DATA_DIRS / LD_PRELOAD(libssh2) / GIO modules / the auto-update config --
# and splice the Wayland fixes into that script's text right after it is
# generated.  Text is spliced (rather than a second `wrapProgram`) because
# `wrapGAppsHook3` may later rewrite `bin/qq` into an ELF shim that execs the
# script as `.qq-wrapped`: whatever ends up in the script at this point is what
# survives, whereas a wrapper layer added here can be consumed and discarded.
qq.overrideAttrs (final: {
  installPhase = final.installPhase + ''
    # --- linuxqq-wayland-fix ---------------------------------------------
    # `wrapGAppsHook3` (fixupPhase) runs after this and re-wraps bin/qq, so
    # splice the injection in now: text added here travels with the script
    # that is finally executed.  It goes after the shebang, on line 2.
    qq_wrapper="$out/bin/qq"
    {
      head -n1 "$qq_wrapper"
      cat ${writeText "linuxqq-injection.sh" injection}
      tail -n +2 "$qq_wrapper"
    } > "$qq_wrapper.new"
    mv "$qq_wrapper.new" "$qq_wrapper"
    chmod +x "$qq_wrapper"
  '';

  meta = (final.meta or { }) // {
    description = "Linux QQ (Tencent QQ) with the upstream Wayland screen-sharing, clipboard and screenshot fixes injected";
    longDescription = ''
      A drop-in replacement for nixpkgs' `qq`: the same official Tencent QQ,
      with the LD_PRELOAD libraries from
      github.com/SHORiN-KiWATA/linuxqq-wayland-fix injected so screen sharing,
      shared computer audio, the clipboard and the screenshot key work under
      Wayland.  The unpatched QQ is not installed alongside it.
    '';
  };

  passthru = (final.passthru or { }) // {
    inherit waylandFix;
  };
})
