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
in
{ inherit scanNixFiles; } // (import ./filesystem.nix lib) // (import ./string.nix lib)
