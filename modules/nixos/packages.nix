{ pkgs, ... }:
{
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
    tealdeer
    lazygit
    lftp
    clock-rs
    trashy
    wiremix
    obs-studio
    chafa
    hyperfine

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
    graalvmPackages.graalvm-oracle

    # nix
    comma
    nh
    home-manager
    nix-index
    nix-inspect
    manix
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
      nix-direnv = {
        enable = true;
      };
    };

    neovim = {
      enable = true;

      viAlias = true;
      vimAlias = true;
    };
  };
}
