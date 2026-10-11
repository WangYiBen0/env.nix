lib: {
  listSubDir =
    dir:
    (builtins.attrNames (
      lib.attrsets.filterAttrs (_name: value: value == "directory") (builtins.readDir dir)
    ));

  # Mirror nixpkgs' pkgs/by-name layout: two-character shard directories,
  # each holding <name>/package.nix, exposed as a flat attrset keyed by name.
  packagesFromByName =
    {
      callPackage,
      directory,
    }:
    let
      inherit (builtins) readDir;

      shards = lib.attrsets.attrNames (
        lib.attrsets.filterAttrs (_name: type: type == "directory") (readDir directory)
      );

      shardPackages =
        shard:
        lib.attrsets.mapAttrs (name: _type: callPackage (directory + "/${shard}/${name}/package.nix") { }) (
          lib.attrsets.filterAttrs (_n: t: t == "directory") (readDir (directory + "/${shard}"))
        );
    in
    lib.attrsets.mergeAttrsList (map shardPackages shards);
}
