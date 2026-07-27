{ lib, myLib, ... }@inputs:
let
  users = myLib.listSubDir ./.;
in
{
  imports = lib.concatMap (username: [
    ./${username}/nixos-module
  ]) users;

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users = lib.genAttrs users (username: ./${username});
  };
}
