{
  users.users.w1ngd1nga5ter = {
    isNormalUser = true;
    description = "W1ngD1nGa5ter";
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

  users.groups.w1ngd1nga5ter = { };
}
