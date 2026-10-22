{
  modulesPath,
  lib,
  pkgs,
  ...
}:
# The rescue/live image. Exposed as `images.<system>.livecd` (outputs/images.nix)
# and deliberately a module file next to default.nix rather than a host
# directory: hosts here are discovered by listing this directory, and every
# discovered host becomes a `nixosConfiguration` that CI builds in full — the
# last thing that build needs is a 1.5 GB ISO closure.
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

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

  # The CD profile already logs root in on the console with no password, so ssh
  # only matters when the machine has no usable console. Key-only, root-only.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDA6dYfSsjK76zMXmIHrPhI+DBc1n4HkGQAsdb9ekTMw w1ngd1nga5ter@nixos-matebook16d"
  ];

  # Repairing a machine is a flake operation, and this is where it happens.
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Shown by the boot menu and by ssh, so it is obvious which system answered.
  networking.hostName = lib.mkDefault "livecd";
  isoImage.edition = lib.mkForce "livecd";
}
