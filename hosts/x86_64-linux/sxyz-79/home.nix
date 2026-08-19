{ self, inputs, ... }:
{
  imports = [
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
