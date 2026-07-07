{ pkgs, ... }:
{
  programs = {
    bash.enable = true;
    fish = {
      enable = true;
      functions = {
        fish_greeting = "";
      };
    };

    bat = {
      enable = true;
      extraPackages = with pkgs.bat-extras; [
        batman
        batwatch
      ];
    };

    eza = {
      enable = true;
      icons = "auto";
    };

    zellij = {
      enable = true;
    };

    zoxide = {
      enable = true;
    };
  };

  home.shellAliases = {
    clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    cat = "bat --paging never --style plain";
    man = "batman";
  };
}
