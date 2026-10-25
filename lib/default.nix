{ lib }:

let
  # Collect the modules of one area directory.
  #
  # Two shapes are supported, and nothing else is descended into:
  #
  #   <area>/<name>.nix              one module
  #   <area>/<name>/default.nix       one module that needs more than one file
  #
  # The second shape is what lets a module keep data beside itself (lockfiles,
  # plugin declarations, helper scripts) without those files being imported as
  # modules of their own — which is why this does not recurse: a directory
  # without a `default.nix` is data, not modules.
  #
  # `_`/`__` prefixed names are skipped, matching the module system's own
  # convention for files that are meant to stay private. `_file` is set to the
  # module's real path: the module system deduplicates definitions by that key,
  # and callers import some of these both by path and through their directory.
  scanNixFiles =
    dir:
    let
      entries = builtins.readDir dir;
      isModuleFile = name: builtins.match "[^_].*\\.nix" name != null && name != "default.nix";
      fileModules = builtins.filter (name: isModuleFile name && entries.${name} == "regular") (
        builtins.attrNames entries
      );
      dirModules = builtins.filter (
        name: entries.${name} == "directory" && builtins.pathExists (dir + "/${name}/default.nix")
      ) (builtins.attrNames entries);
    in
    map (name: {
      _file = dir + "/${name}";
      imports = [ (dir + "/${name}") ];
    }) fileModules
    ++ map (name: {
      _file = dir + "/${name}/default.nix";
      imports = [ (dir + "/${name}/default.nix") ];
    }) dirModules;
in
{ inherit scanNixFiles; } // (import ./filesystem.nix lib) // (import ./string.nix lib)
