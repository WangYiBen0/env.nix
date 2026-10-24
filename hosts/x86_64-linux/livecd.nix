{
  modulesPath,
  lib,
  pkgs,
  ...
}:
# The rescue/live image, exposed as `nixosConfigurations.livecd` (minted in
# default.nix next to the host directories). A module file rather than a host
# directory because it is a system, not a machine: nothing ever switches to it.
#
#   nix build .#nixosConfigurations.livecd.config.system.build.isoImage
#   nix build .#nixosConfigurations.livecd.config.system.build.vm
{
  imports = [
    "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix"

    # The repository's own modules, so the image inherits the settings the
    # machines run instead of restating them: `nix` brings the substituters,
    # caches and flakes, `system` the timezone/locale/kernel, `services` the ssh
    # daemon and the firewall. `profiles/` is deliberately NOT imported —
    # profiles/desktop.nix would pull plasma, niri and the font stack into the
    # image — so only the three modules below are switched on, and everything
    # else stays off by default.
    ../../modules/common
    ../../modules/nixos
  ];

  machine.modules = {
    nix.enable = true;
    system.enable = true;
    services.enable = true;
  };

  # Minimal installer plus the tools this fleet's repair jobs need: btrfs and
  # disko to create and seed the /persist subvolume, lsof to find what still
  # holds a mount, rsync to move state off a running system, smart/nvme to see
  # whether the disk is the reason the machine is broken. No desktop — the
  # image is booted to fix a machine, and everything here still fits in RAM.
  environment.systemPackages = with pkgs; [
    btrfs-progs
    disko
    gptfdisk
    parted
    dosfstools
    e2fsprogs
    zstd
    rsync
    pv

    lsof
    tmux
    htop

    jq
    ripgrep
    fd
    file

    smartmontools
    nvme-cli
    usbutils
    pciutils
    ethtool
  ];

  # machine.modules.system pins linuxPackages_latest for the desktops, and the
  # installer profile keeps ZFS support — zfs is the thing that drags a kernel
  # module into the initrd, and the latest kernel's zfs is marked broken. Hold
  # the image at the installer's own stable kernel instead.
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages;

  # machine.modules.services is written for the desktops, so an image that boots
  # to a console switches the parts it cannot use back off.
  services = {
    # CUPS drags in samba, mupdf and ghostscript — about 380 MB of the image
    # (1269 paths against 784 when the module was first reused) for printers
    # that are not there — and blueman is a desktop applet.
    printing.enable = lib.mkForce false;
    blueman.enable = lib.mkForce false;

    # autoScrub asserts a mounted btrfs filesystem; an ISO has none (its
    # fileSystems are the image media override).
    btrfs.autoScrub.enable = lib.mkForce false;

    # No key is baked into the image. The installer profile auto-logs in as
    # `nixos` on the console with an empty password; for a machine whose console
    # is unusable, boot with `live.nixos.passwd=<password>` on the kernel command
    # line, which the profile turns into that account's password, and ssh in as
    # `nixos` (password auth is on by upstream default). Root stays key-only:
    # with password auth enabled there is no reason to accept root logins with a
    # password, and the image has no key to accept.
    openssh.settings.PermitRootLogin = "prohibit-password";
  };

  # Shown by the boot menu and by ssh, so it is obvious which system answered.
  networking.hostName = lib.mkDefault "livecd";
  isoImage.edition = lib.mkForce "livecd";

  # The same system booted as a throwaway VM, which is the cheap way to poke at
  # the rescue environment without writing a USB stick. The knobs belong under
  # vmVariant: qemu-vm.nix is only imported into that deferred module (see
  # nixos/modules/virtualisation/build-vm.nix, which aliases system.build.vm to
  # the variant), so `virtualisation.graphics` does not exist in this config.
  virtualisation.vmVariant = {
    virtualisation = {
      graphics = false;
      memorySize = 2048;
      diskSize = 4096;
    };
    boot.kernelParams = [ "console=ttyS0,115200" ];
  };
}
