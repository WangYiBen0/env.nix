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
        nix-update
      ];
      inherit (self.checks.${system}.pre-commit) shellHook;
    };
  }
)
