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
  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
      overlays = import ../overlays inputs;
    };

  hostsDir = ./../hosts/x86_64-linux;
  hostNames = builtins.filter (name: builtins.pathExists (hostsDir + "/${name}/home")) (
    myLib.listSubDir hostsDir
  );
  allUsers = builtins.concatMap (
    host:
    let
      homeDir = hostsDir + "/${host}/home";
      userNames = builtins.filter (name: builtins.pathExists (homeDir + "/${name}/standalone")) (
        myLib.listSubDir homeDir
      );
    in
    map (user: { inherit host user; }) userNames
  ) hostNames;

  # standalone 模式下设置 nix.package，NixOS module 模式会继承系统配置
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
            write = true; # Automatically format files
          };
        };

        statix.enable = true;

        typos = {
          enable = true;
          settings = {
            write = true; # Automatically fix typos
          };
        };
      };
    };
  });

  # Development Shells
  devShells = forAllSystems (
    system:
    let
      pkgs = pkgsFor system;
    in
    {
      default = pkgs.mkShell {
        packages = with pkgs; [
          # Nix-related
          nixfmt
          deadnix
          statix
          # spell checker
          typos
          # code formatter
          prettier
        ];
        inherit (self.checks.${system}.pre-commit) shellHook;
      };
    }
  );

  inherit (import ./../hosts inputs) nixosConfigurations;

  homeConfigurations = builtins.listToAttrs (
    map (
      {
        host,
        user,
      }:
      {
        name = "${user}@${host}";
        value = inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = pkgsFor "x86_64-linux";
          modules = [
            (hostsDir + "/${host}/home/${user}")
            (hostsDir + "/${host}/home/${user}/standalone")
            standaloneNixModule
          ];
          extraSpecialArgs = {
            inherit self inputs;
          };
        };
      }
    ) allUsers
  );
}
