lib: {
  listSubDir =
    dir:
    (builtins.attrNames (
      lib.attrsets.filterAttrs (_name: value: value == "directory") (builtins.readDir dir)
    ));
}
