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
      };
      statix.enable = true;
      typos.enable = true;
    };
  };
  test = (pkgsFor system).hello;
})
