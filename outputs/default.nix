{
  self,
  nixpkgs,
  git-hooks,
  ...
}@inputs:
let
  myLib = import ./../lib/default.nix nixpkgs.lib;
  allSystems = myLib.listSubDir ./.;
  forAllSystems = func: (nixpkgs.lib.genAttrs allSystems func);

  overlayFn = import ../overlays inputs;

  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
      overlays = [ overlayFn ];
    };

  hostsBaseDir = ./../hosts;
  architectures = myLib.listSubDir hostsBaseDir;

  allUserEntries = builtins.concatMap (
    arch:
    let
      hostsDir = hostsBaseDir + "/${arch}";
      hostNames = builtins.filter (name: builtins.pathExists (hostsDir + "/${name}/home")) (
        myLib.listSubDir hostsDir
      );
    in
    builtins.concatMap (
      host:
      let
        homeDir = hostsDir + "/${host}/home";
        userNames = builtins.filter (name: builtins.pathExists (homeDir + "/${name}/standalone")) (
          myLib.listSubDir homeDir
        );
      in
      map (user: {
        inherit host user;
        system = arch;
      }) userNames
    ) hostNames
  ) architectures;

  standaloneNixModule = { pkgs, ... }: { nix.package = pkgs.lix; };
in
{
  lib = myLib;

  formatter = forAllSystems (system: (pkgsFor system).nixfmt);

  checks = forAllSystems (system: {
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

        typos = {
          enable = true;
          settings = {
            write = true;
          };
        };
      };
    };
  });

  devShells = forAllSystems (
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
  );

  packages = forAllSystems (system: myLib.scanPackages (pkgsFor system) ../pkgs);

  overlays.default = overlayFn;

  inherit (import ./../hosts inputs) nixosConfigurations;

  homeConfigurations = builtins.listToAttrs (
    map (
      {
        host,
        user,
        system,
      }:
      {
        name = "${user}@${host}";
        value = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor system;
          modules = [
            (hostsBaseDir + "/${system}/${host}/home/${user}")
            (hostsBaseDir + "/${system}/${host}/home/${user}/standalone")
            standaloneNixModule
          ];
          extraSpecialArgs = {
            inherit self inputs;
          };
        };
      }
    ) allUserEntries
  );
}
