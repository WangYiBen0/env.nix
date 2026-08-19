{ lib, myLib, ... }@inputs:
let
  users = myLib.listSubDir ./.;
in
{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users = lib.genAttrs users (username: ./${username});
  };
}
