{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.machine.modules.impermanence;

  # The state that must outlive the root filesystem. /home is its own btrfs
  # subvolume (@home / nixos/@home), so user data is already safe and
  # deliberately absent here — this is the state that would otherwise live
  # under /.
  #
  # Nothing in this list has to be enabled today: / is still a persistent
  # subvolume. It exists so that making / ephemeral later is a one-line change
  # instead of an inventory exercise.
  stateDirectories = [
    # uid/gid map — recreating it can renumber existing users' files
    "/var/lib/nixos"
    # saved Wi-Fi/VPN connections
    "/var/lib/NetworkManager"
    # bluetooth pairings
    "/var/lib/bluetooth"
    # application data of everything installed through flatpak
    "/var/lib/flatpak"
    # podman storage (and its docker alias)
    "/var/lib/containers"
    "/var/lib/docker"
    # honk: subscriptions, node lists, the UI-edited base.dae
    "/var/lib/honk"
    # keeps user sessions alive across logins
    "/var/lib/systemd/linger"
  ];

  # Regenerated host keys would change the machine's SSH identity on every
  # rebuild of an ephemeral root, breaking known_hosts and key-based automation.
  stateFiles = [
    "/etc/ssh/ssh_host_ed25519_key"
    "/etc/ssh/ssh_host_ed25519_key.pub"
    "/etc/ssh/ssh_host_rsa_key"
    "/etc/ssh/ssh_host_rsa_key.pub"
  ];
in
{
  imports = [ inputs.preservation.nixosModules.preservation ];
  # ^ keep imports outside mkIf: module imports are unconditional, the config
  # below is not.

  config = lib.mkIf cfg.enable {
    # The /persist mount itself comes from disko (`nixos/@persist` in the
    # host's disko.nix), which is also what creates the subvolume on install.
    # Assert instead of guessing: a missing mount means the bind mounts below
    # point at the ephemeral root and the state silently lands in the wrong
    # place.
    assertions = [
      {
        assertion = config.fileSystems ? "/persist";
        message = ''
          machine.modules.impermanence.enable is on, but nothing mounts /persist.
          Add a subvolume to ${config.networking.hostName}'s disko.nix:
            "nixos/@persist" = { mountpoint = "/persist"; mountOptions = [ "compress=zstd" ]; };
          and create it once on the running system (see modules/README.md).
        '';
      }
    ];

    preservation = {
      enable = true;

      preserveAt."/persist" = {
        directories = stateDirectories;
        files = stateFiles;
      };
    };
  };
}
