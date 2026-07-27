{ pkgs, ... }:
{
  users.users = {
    administrator = {
      isNormalUser = true;
      description = "Administrator";
      extraGroups = [ "wheel" ];
    };

    w1ngd1nga5ter = {
      isNormalUser = true;
      description = "W1ngD1nGa5ter";
      shell = pkgs.fish;
      extraGroups = [
        "wheel"
        "video"
        "audio"
        "networkmanager"
        "libvirtd"
        "kvm"
        "docker"
        "podman"
      ];
    };
  };
}
