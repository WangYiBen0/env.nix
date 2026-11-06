inputs: final: prev:
let
  myLib = import ../lib/default.nix {
    inherit (inputs.nixpkgs) lib;
  };

  # opencode 2.2.5 shipped a stale fixed-output hash: `bun install` no longer
  # produces the tree the pin describes, so the package refuses to build
  # ("hash mismatch in fixed-output derivation
  # ...-opencode-node_modules-2.2.5").  Upstream fixed it in
  # NixOS/nixpkgs@c399e1b7fb90, which is newer than the revision this flake
  # pins.  Rather than bump the whole nixpkgs input for one line, patch the
  # single fixed-output hash here.
  #
  # The guard keys off the known-bad value, so once the pin catches up this
  # becomes a no-op and the block can be deleted.
  staleOpencodeHash = "sha256-xfOVcw1+waLVNhFDwzOtzxrUSQEogvn88YomydOlhwc=";
  opencodeHash =
    if prev.stdenv.hostPlatform.isLinux then
      "sha256-prx9dX7kUvs/E3zopkaPk5LXh3xJAy5sZeum/W8L7cA="
    else
      "sha256-dIveiaiPFGSItwLyeMuPDxTE9gpvvnlTCB/+nG24qCc=";

  opencode =
    if prev.opencode.node_modules.outputHash == staleOpencodeHash then
      prev.opencode.overrideAttrs (old: {
        node_modules = old.node_modules.overrideAttrs (_: {
          outputHash = opencodeHash;
        });
      })
    else
      prev.opencode;

  # WebKitGTK 2.54.1 has a compositing regression that makes the web process
  # allocate gigabytes and hang: with ~20+ elements carrying `backdrop-filter`
  # the compositing work grows as 2^n (WebKit bugs 327701 / 328065).  CeleMod
  # draws a `backdrop-filter: blur(10px)` badge over every mod cover, so opening
  # the mod manager freezes the app; upstream's AppImage is unaffected because
  # it bundles WebKitGTK 2.50.4.
  #
  # Fixed in 2.54.2 ("Fix performance when compositing layers with backdrop
  # filters").  nixpkgs master already has it, the revision pinned here does
  # not.  The resulting derivation is byte-for-byte the one nixpkgs builds (same
  # store hash), so cache.nixos.org serves it and nothing is compiled locally.
  #
  # webkitgtk_4_1 is webkitgtk_6_0 with `gtk4 = gtk3`; rebuilding it from the
  # bumped base keeps both ABIs in step.  Guarded on the known-broken version,
  # so once the pin moves past 2.54.1 this becomes a no-op.
  webkitgtk_6_0 =
    if prev.webkitgtk_6_0.version == "2.54.1" then
      prev.webkitgtk_6_0.overrideAttrs (_: {
        version = "2.54.2";
        src = prev.fetchurl {
          url = "https://webkitgtk.org/releases/webkitgtk-2.54.2.tar.xz";
          hash = "sha256-p2NFs5G+9iEftats+rLoayhdGM2hfLua3llfElK4YGU=";
        };
      })
    else
      prev.webkitgtk_6_0;
  webkitgtk_4_1 = final.webkitgtk_6_0.override { gtk4 = final.gtk3; };
in
{
  inherit opencode webkitgtk_4_1 webkitgtk_6_0;
}
// myLib.packagesFromByName {
  inherit (prev) callPackage;
  directory = ../pkgs/by-name;
}
