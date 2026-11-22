{
  forAllSystems,
  pkgsFor,
  git-hooks,
  ...
}:

forAllSystems (system: {
  pre-commit = git-hooks.lib.${system}.run {
    src = ./..;
    hooks = {
      nixfmt.enable = true;
      deadnix.enable = true;
      # prettier disabled: it scans node_modules inside the nix store (src=./..)
      # and reformat-locked JSON it should not touch. nixfmt covers Nix files.
      prettier.enable = false;
      statix.enable = true;
      typos = {
        enable = true;
        # npm lockfiles under modules/home/deepseek-harness/* mix npm package names into
        # what looks like prose, so the spell checker flags identifiers there.
        excludes = [
          "^modules/home/deepseek-harness/npm-locks/"
          "^modules/home/deepseek-harness/plugin-locks/"
        ];
      };
    };
  };
  test = (pkgsFor system).hello;
})
