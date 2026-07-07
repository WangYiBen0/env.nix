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
builtins.foldl' (acc: file: acc // (import file lib)) { inherit scanNixFiles; } (scanNixFiles ./.)
