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
      prettier = {
        enable = true;
        settings = {
          write = true;
        };
        # The npm lockfiles under modules/home/deepseek-harness/npm-locks/ are packaging inputs:
        # they are consumed verbatim by the offline dependency fetch, and
        # `npm install --package-lock-only` decides their layout. Reformatting
        # them only adds noise to every future regeneration.
        excludes = [ "^modules/home/deepseek-harness/npm-locks/" ];
      };
      statix.enable = true;
      typos = {
        enable = true;
        # The lockfiles under modules/home/deepseek-harness/npm-locks/ mix npm package names into
        # what looks like prose, so the spell checker flags identifiers there.
        excludes = [ "^modules/home/deepseek-harness/npm-locks/" ];
      };
    };
  };
  test = (pkgsFor system).hello;
})
