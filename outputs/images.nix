{
  nixpkgs,
  forAllSystems,
  ...
}:
forAllSystems (
  system:
  let
    # A module file rather than a host directory, so host discovery
    # (`listSubDir` in hosts/<arch>/default.nix) does not turn it into a
    # nixosConfiguration.
    livecdSystem =
      extraModules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ ./../hosts/${system}/livecd.nix ] ++ extraModules;
      };
  in
  {
    # Kept out of nixosConfigurations and out of packages on purpose: CI builds
    # every toplevel and every package whenever outputs/ changes, and a roughly
    # 1.5 GB image has no business in either list. Build it by hand:
    #   nix build .#images.${system}.livecd
    livecd = (livecdSystem [ ]).config.system.build.isoImage;

    # The same rescue environment as a bootable VM, so it can be tried (and
    # broken) without writing anything to a USB stick. Headless on purpose:
    # there is no X in the image, so the console is the serial line.
    #   nix build .#images.${system}.livecd-vm
    #   ./result/bin/run-livecd-vm
    #
    # The knobs sit under `virtualisation.vmVariant` rather than at the top
    # level: qemu-vm.nix is only imported into that deferred module here
    # (see nixos/modules/virtualisation/build-vm.nix, which also aliases
    # `system.build.vm` to the variant), so `virtualisation.graphics` does not
    # even exist in the outer configuration.
    livecd-vm =
      (livecdSystem [
        {
          virtualisation.vmVariant = {
            virtualisation = {
              graphics = false;
              memorySize = 2048;
              diskSize = 4096;
            };
            boot.kernelParams = [ "console=ttyS0,115200" ];
          };
        }
      ]).config.system.build.vm;
  }
)
