{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.starship.enable {
  programs = {
    starship = {
      enable = true;

      settings = {
        # Don't print a new line at the start of the prompt
        add_newline = false;

        # Pipes ╰─ ╭─
        # Powerline symbols                                    
        # Wedges 🭧🭒 🭣🭧🭓
        # Random noise 🬖🬥🬔🬗
        # Cool stuff 󰜥   

        # Main format
        format = ''
          $shlvl $username $cmd_duration 󰜥 $directory$git_branch$nix_shell$python
            $character'';

        fill = {
          symbol = "-";
          style = "fg:245";
        };

        # Replace the "❯" symbol in the prompt with "➜"
        character = {
          success_symbol = "[ ](bold fg:blue)";
          error_symbol = "[ ](bold fg:red)";
        };

        package.disabled = true;

        git_branch = {
          style = "bg: cyan";
          symbol = "󰘬";
          truncation_length = 12;
          truncation_symbol = "";
          format = " 󰜥 [](bold fg:cyan)[$symbol $branch(:$remote_branch)](fg:black bg:cyan)[](bold fg:cyan)";
        };

        git_commit = {
          commit_hash_length = 4;
          tag_symbol = " ";
        };

        git_state = {
          format = "([$state( $progress_current of $progress_total)]($style) )";
          cherry_pick = "[🍒 PICKING](bold red)";
        };

        git_status = {
          conflicted = " 🏳 ";
          ahead = " 🏎💨 ";
          behind = " 😰 ";
          diverged = " 😵 ";
          untracked = " 🤷 ‍";
          stashed = " 📦 ";
          modified = " 📝 ";
          staged = "[++($count)](green)";
          renamed = " ✍️ ";
          deleted = " 🗑 ";
        };

        hostname = {
          ssh_only = false;
          format = "[•$hostname](bg:cyan bold fg:black)[](bold fg:cyan)";
          trim_at = ".companyname.com";
          disabled = false;
        };

        line_break.disabled = false;

        memory_usage = {
          disabled = true;
          threshold = -1;
          symbol = " ";
          style = "bold dimmed green";
        };

        time = {
          disabled = true;
          format = "🕙[[ $time ]]($style) ";
          time_format = "%T";
        };

        username = {
          style_user = "bold bg:cyan fg:black";
          style_root = "red bold";
          format = "[](bold fg:cyan)[$user]($style)[](bold fg:cyan)";
          disabled = false;
          show_always = true;
        };

        directory = {
          home_symbol = "  ";
          read_only = "  ";
          style = "bg:green fg:black";
          truncation_length = 8;
          truncation_symbol = " ••/";
          format = "[](bold fg:green)[󰉋 ➜$path]($style)[](bold fg:green)";
          substitutions = {
            "Desktop" = "  ";
            "Documents" = "  ";
            "Downloads" = "  ";
            "Music" = " 󰎈 ";
            "Pictures" = "  ";
            "Videos" = "  ";
            "GitHub" = " 󰊤 ";
            "Projects" = "  ";
          };
        };

        cmd_duration = {
          min_time = 0;
          format = "[](bold fg:yellow)[󰪢 $duration](bold bg:yellow fg:black)[](bold fg:yellow)";
        };

        rust = {
          disabled = false;
          symbol = "󱘗 ";
          style = "bold bg:red fg:black";
          format = " 󰜥 [](bold fg:red)[$symbol$version]($style)[](bold fg:red)";
          version_format = "v$raw";
        };

        # Disabled because ~/.nix-profile/bin/python on this host is a stray
        # Python 3.7.4 (installed by hand from cachix/nixpkgs-python) and sits
        # first on PATH. Starting it costs ~350 ms and routinely exceeds
        # starship's command timeout, so every prompt printed the
        # "Executing command ... timed out" warning. Nothing in this
        # configuration uses that interpreter.
        python = {
          disabled = true;
        };

        nix_shell = {
          disabled = false;
          symbol = "󱄅 ";
          format = " 󰜥 [](bold fg:peach)[$symbol$state](bold bg:peach fg:black)[](bold fg:peach)";
        };

        shlvl = {
          disabled = false;
          symbol = " ";
          repeat = false;
          format = "[](bold fg:mauve)[$symbol$shlvl](bold bg:mauve fg:black)[](bold fg:mauve)";
        };
      };
    };
  };
}
