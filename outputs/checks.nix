{
  nixpkgs,
  forAllSystems,
  git-hooks,
  hosts,
  ...
}:

forAllSystems (
  system:
  {
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
  }
  //
    nixpkgs.lib.mapAttrs'
      (name: cfg: nixpkgs.lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel)
      (
        nixpkgs.lib.filterAttrs (
          _: cfg: cfg.config.nixpkgs.hostPlatform.system == system
        ) hosts.nixosConfigurations
      )
  // nixpkgs.lib.mapAttrs' (
    name: cfg: nixpkgs.lib.nameValuePair "home-${name}" cfg.config.home.activationPackage
  ) (nixpkgs.lib.filterAttrs (_: cfg: cfg.config.nixpkgs.system == system) hosts.homeConfigurations)
)
