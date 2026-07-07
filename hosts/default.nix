{ nixpkgs, ... }@args:
let
  myLib = import ../lib nixpkgs.lib;
  allSystems = myLib.listSubDir ./.;
  linuxSystems = builtins.filter (system: (myLib.lastAfterDash system) == "linux") allSystems;

  # 每个架构目录返回自己的 { hostname = nixosSystem; ... }
  perSystemConfigs = map (
    system: import (./. + "/${system}") (args // { inherit system; })
  ) linuxSystems;
in
{
  nixosConfigurations = builtins.foldl' (acc: cfgs: acc // cfgs) { } perSystemConfigs;
}
