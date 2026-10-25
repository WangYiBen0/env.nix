{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.shell.enable {
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
      settings = {
        ui.pane_frames.rounded_corners = true;
        show_startup_tips = false;
      };
    };

    zoxide = {
      enable = true;
    };
  };

  # `dsh` installs bash/zsh/fish completions under its own `share/`. fish picks
  # them up from share/fish/vendor_completions.d automatically; bash only
  # sources share/bash-completion once bash-completion itself is enabled, and
  # the dsh package alone is inert without it. zsh reads
  # share/zsh/site-functions from fpath, which the profile already contributes —
  # it still needs `programs.zsh` to run compinit, the way bash needs
  # bash-completion; zsh is not enabled on this host, so nothing to wire yet.
  programs.bash.enableCompletion = true;

  home.shellAliases = {
    clear = "printf '\\033[2J\\033[3J\\033[1;1H'";
    cat = "bat --paging never --style plain";
    man = "batman";
  };
}
