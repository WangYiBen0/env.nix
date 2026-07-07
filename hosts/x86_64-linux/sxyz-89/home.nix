{ self, inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./home/nixos-module.nix
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit self inputs;
    };
  };
}
