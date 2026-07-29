{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # basic
    git
    curl
    wget
    neovim
    zsh
    fish
    kitty
    zimfw
    starship
    file
    zip
    unzip
    rar
    unrar
    _7zz

    # utils
    fastfetch
    btop
    brightnessctl
    yazi
    ripgrep
    zellij
    fzf
    fd
    eza
    wl-clipboard
    xclip
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

    # im
    qq

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
