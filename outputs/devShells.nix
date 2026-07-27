{
  self,
  forAllSystems,
  pkgsFor,
  ...
}:

forAllSystems (
  system:
  let
    pkgs = pkgsFor system;
  in
  {
    default = pkgs.mkShell {
      packages = with pkgs; [
        nixfmt
        deadnix
        statix
        typos
        prettier
      ];
      inherit (self.checks.${system}.pre-commit) shellHook;
    };
  }
)
