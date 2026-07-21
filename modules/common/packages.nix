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
    stylua
    tree-sitter
    clang-tools
    lftp
    clock-rs
    trashy
    wiremix

    # im
    qq

    # develop
    gcc
    clang
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
