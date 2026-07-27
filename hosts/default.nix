{ nixpkgs, ... }@inputs:
let
  myLib = import ../lib nixpkgs.lib;
  allSystems = myLib.listSubDir ./.;

  linuxSystems = builtins.filter (system: (myLib.lastAfterDash system) == "linux") allSystems;

  pkgsFor =
    system:
    import nixpkgs {
      inherit system;
      overlays = [ (import ../overlays inputs) ];
    };

  allUserEntries = builtins.concatMap (
    system:
    let
      hostsDir = ./${system};
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
      map (user: { inherit host user system; }) userNames
    ) hostNames
  ) allSystems;
in
{
  nixosConfigurations = builtins.foldl' (acc: cfgs: acc // cfgs) { } (
    map (system: import ./${system} (inputs // { inherit system; })) linuxSystems
  );

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
            ../modules/common
            ../modules/home
            ../modules/home-standalone
            ./${system}/${host}/home/${user}
            ./${system}/${host}/home/${user}/standalone
          ];
          extraSpecialArgs = {
            inherit inputs;
            inherit (inputs) self;
          };
        };
      }
    ) allUserEntries
  );
}
