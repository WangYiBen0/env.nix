{ pkgs, lib, ... }:
{
  programs.yazi = {
    enable = true;
    shellWrapperName = "y";
    plugins =
      let
        setupAll = lib.mapAttrs (
          name: settings: {
            package = pkgs.yaziPlugins.${name};
            inherit settings;
            setup = true;
          }
        );
      in
      {
        inherit (pkgs.yaziPlugins)
          chmod
          diff
          mount
          sudo
          yatline
          yatline-catppuccin
          yatline-githead
          ;
      }
      // setupAll {
        full-border = { };
        git = {
          order = 1500;
        };
      };

    initLua = ''
      local yatline_theme = require("yatline-catppuccin"):setup("macchiato")

      require("yatline"):setup {
        theme = yatline_theme,
      }
      require("yatline-githead"):setup {
        theme = yatline_theme,
      }
    '';

    keymap = {
      mgr.prepend_keymap = [
        # mount.yazi
        {
          on = "M";
          run = "plugin mount";
        }

        # sudo.yazi
        # # sudo cp/mv
        {
          on = [
            "R"
            "p"
            "p"
          ];
          run = "plugin sudo -- paste";
          desc = "sudo paste";
        }

        # # sudo cp/mv --force
        {
          on = [
            "R"
            "P"
          ];
          run = "plugin sudo -- paste --force";
          desc = "sudo paste";
        }
        # # sudo mv
        {
          on = [
            "R"
            "r"
          ];
          run = "plugin sudo -- rename";
          desc = "sudo rename";
        }
        # # sudo ln -s (absolute-path)
        {
          on = [
            "R"
            "p"
            "l"
          ];
          run = "plugin sudo -- link";
          desc = "sudo link";
        }
        # # sudo ln -s (relative-path)
        {
          on = [
            "R"
            "p"
            "r"
          ];
          run = "plugin sudo -- link --relative";
          desc = "sudo link relative path";
        }
        # # sudo ln
        {
          on = [
            "R"
            "p"
            "L"
          ];
          run = "plugin sudo -- hardlink";
          desc = "sudo hardlink";
        }
        # # sudo touch/mkdir
        {
          on = [
            "R"
            "a"
          ];
          run = "plugin sudo -- create";
          desc = "sudo create";
        }
        # # sudo trash
        {
          on = [
            "R"
            "d"
          ];
          run = "plugin sudo -- remove";
          desc = "sudo trash";
        }
        # # sudo delete
        {
          on = [
            "R"
            "D"
          ];
          run = "plugin sudo -- remove --permanently";
          desc = "sudo delete";
        }
        # # sudo chmod
        {
          on = [
            "R"
            "m"
          ];
          run = "plugin sudo -- chmod";
          desc = "sudo chmod";
        }
      ];
    };

    settings = {
      plugin.prepend_fetchers = [
        # git.yazi
        {
          id = "git"; # Remove if Yazi > v26.1.22
          url = "*";
          run = "git";
          group = "git";
        }
        {
          id = "git"; # Remove if Yazi > v26.1.22
          url = "*/";
          run = "git";
          group = "git";
        }
      ];
    };
  };
}
