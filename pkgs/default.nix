{ callPackage }:
let
  scanDir =
    dir:
    builtins.listToAttrs (
      map (name: {
        inherit name;
        value = callPackage (dir + "/${name}/package.nix") { };
      }) (builtins.attrNames (builtins.readDir dir))
    );
in
scanDir ./fonts
