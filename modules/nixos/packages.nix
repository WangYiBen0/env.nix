{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.packages.enable {
  environment.systemPackages = with pkgs; [
    # basic
    git
    git-lfs
    curl
    wget
    aria2
    neovim
    zsh
    zimfw
    fish
    kitty
    starship
    file
    zip
    unzipNLS
    rar
    unrar
    _7zz
    ntfsprogs-plus
    exfatprogs
    pciutils

    # utils
    fastfetch
    btop
    procs
    httpie
    curlie
    doggo
    ipcalc
    iperf3
    tcpdump
    gping
    dust
    duf
    brightnessctl
    yazi
    exiftool
    ripgrep
    zellij
    fzf
    fd
    eza
    jq
    yq-go
    jc
    sad
    wl-clipboard
    wayland-utils
    xdg-utils
    desktop-file-utils
    tealdeer
    lftp
    clock-rs
    trashy
    wiremix
    obs-studio
    chafa
    hyperfine
    bubblewrap

    # develop
    gcc
    clang
    clang-tools
    stylua
    tree-sitter
    cargo
    rustc
    rustfmt
    python3
    texliveFull
    # graalvm-oracle-25's installCheck runs jshell, which segfaults (exit
    # 139) during JVM startup on GitHub-hosted runners — it passes on real
    # hardware (verified locally and in daily use). The canary cannot run
    # there, so skip it to keep the CI closure build alive.
    (graalvmPackages.graalvm-oracle.overrideAttrs (_: {
      doInstallCheck = false;
    }))
    glab

    # nix
    comma
    nh
    home-manager
    nix-index
    nix-inspect
    manix

    # apps
    dingtalk
  ];

  environment.variables = {
    EDITOR = "nvim";
  };

  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    fish.enable = true;
    zsh = {
      enable = true;
      enableBashCompletion = false;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    neovim = {
      enable = true;

      viAlias = true;
      vimAlias = true;
    };
  };
}
