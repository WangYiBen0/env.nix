lib:
let
  scanNixFiles =
    dir:
    map (name: (dir + "/${name}")) (
      builtins.attrNames (
        lib.attrsets.filterAttrs (
          path: type:
          (type == "directory" && builtins.pathExists (dir + "/${path}/default.nix"))
          || ((path != "default.nix") && (lib.strings.hasSuffix ".nix" path))
        ) (builtins.readDir dir)
      )
    );

  scanPackages = import ./packages.nix;
in
{ inherit scanNixFiles scanPackages; } // (import ./filesystem.nix lib) // (import ./string.nix lib)
