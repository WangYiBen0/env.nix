{
  lib,
  haumea,
}:
let
  # haumea (a filesystem-based module system) does the directory walk and the
  # import for us: nested directories become nested attributes, so a directory
  # that grows its own module is picked up without touching this function, and
  # `_`/`__` prefixed entries stay out of the result instead of being imported
  # as modules. The directory's own default.nix is dropped because it is the
  # caller — keeping it here would recurse forever.
  #
  # A loader is called as `loader inputs path`; the inputs argument would only
  # matter for files that reference other flake inputs, which modules do not
  # (they receive those through specialArgs), so each file is just imported.
  # `_file` is set to keep the file's identity: some callers import the same
  # module both through its directory and by path, and the module system only
  # deduplicates entries whose key — the `_file` — matches.
  scanNixFiles =
    dir:
    builtins.attrValues (
      builtins.removeAttrs (haumea.load {
        src = dir;
        loader = [
          (haumea.matchers.nix (
            _inputs: path: {
              _file = path;
              imports = [ path ];
            }
          ))
        ];
      }) [ "default" ]
    );
in
{ inherit scanNixFiles; } // (import ./filesystem.nix lib) // (import ./string.nix lib)
