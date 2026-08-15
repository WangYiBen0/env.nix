{
  config,
  lib,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.niri.enable {
  wayland.windowManager.niri = {
    enable = true;
    package = pkgs.niri-unstable;
    xwaylandSatellitePackage = pkgs.xwayland-satellite-unstable;
    settings = {
      # Input configuration
      input = {
        keyboard.xkb.options = "caps:escape";
        keyboard.numlock = true;

        touchpad = {
          tap = { };
          dwt = { };
          natural-scroll = { };
        };
      };

      # Output configuration: see hosts/

      # Environment variables
      environment = {
        "NIXOS_OZONE_WL" = "1";
        "SDL_VIDEODRIVER" = "wayland";
      };

      # Layout settings
      layout = {
        gaps = 16;
        center-focused-column = "never";

        preset-column-widths._children = [
          { proportion = 0.33333; }
          { proportion = 0.5; }
          { proportion = 0.66667; }
        ];

        default-column-width = {
          proportion = 0.5;
        };

        focus-ring = {
          width = 2;
          active-color = "#7fc8ff";
          inactive-color = "#505050";
        };

        border = {
          off = { };
          width = 2;
          active-color = "#ffc87f";
          inactive-color = "#505050";
          urgent-color = "#9b0000";
        };

        shadow = {
          softness = 30;
          spread = 5;
          offset._props = {
            x = 0;
            y = 5;
          };
          color = "#0007";
        };
      };

      # Startup programs
      spawn-at-startup = [ "ironbar" ];

      # Hotkey overlay
      hotkey-overlay = {
        skip-at-startup = false;
      };

      # Other settings
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";

      # Animations
      animations = { };

      # Window rules
      _children = [
        {
          window-rule._children = [
            {
              match._props = {
                app-id = "^org\\.wezfurlong\\.wezterm$";
              };
            }
            { default-column-width = { }; }
          ];
        }
        {
          window-rule._children = [
            {
              match._props = {
                app-id = "firefox$";
                title = "^Picture-in-Picture$";
              };
            }
            { open-floating = true; }
          ];
        }
        {
          window-rule._children = [
            {
              geometry-corner-radius = [
                12.0
                12.0
                12.0
                12.0
              ];
            }
            { clip-to-geometry = true; }
          ];
        }
      ];

      # Key bindings
      binds = {
        # System
        "Mod+Shift+Slash" = {
          show-hotkey-overlay = { };
          _props.hotkey-overlay-title = "Show Hotkey Overlay";
        };

        # Applications
        "Mod+T" = {
          spawn = [ "kitty" ];
          _props.hotkey-overlay-title = "Open a Terminal: kitty";
        };
        "Mod+D" = {
          spawn = [ "fuzzel" ];
          _props.hotkey-overlay-title = "Run an Application: fuzzel";
        };
        "Super+Alt+L" = {
          spawn = [ "swaylock" ];
          _props.hotkey-overlay-title = "Lock the Screen: swaylock";
        };
        "Super+Alt+S" = {
          spawn-sh = "pkill orca || exec orca";
          _props.allow-when-locked = true;
          _props.hotkey-overlay-title = null;
        };

        # Audio
        "XF86AudioRaiseVolume" = {
          spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
          _props.allow-when-locked = true;
        };
        "XF86AudioLowerVolume" = {
          spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
          _props.allow-when-locked = true;
        };
        "XF86AudioMute" = {
          spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          _props.allow-when-locked = true;
        };
        "XF86AudioMicMute" = {
          spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          _props.allow-when-locked = true;
        };

        # Media
        "XF86AudioPlay" = {
          spawn-sh = "playerctl play-pause";
          _props.allow-when-locked = true;
        };
        "XF86AudioStop" = {
          spawn-sh = "playerctl stop";
          _props.allow-when-locked = true;
        };
        "XF86AudioPrev" = {
          spawn-sh = "playerctl previous";
          _props.allow-when-locked = true;
        };
        "XF86AudioNext" = {
          spawn-sh = "playerctl next";
          _props.allow-when-locked = true;
        };

        # Brightness
        "XF86MonBrightnessUp" = {
          spawn = [
            "brightnessctl"
            "--class=backlight"
            "set"
            "+10%"
          ];
          _props.allow-when-locked = true;
        };
        "XF86MonBrightnessDown" = {
          spawn = [
            "brightnessctl"
            "--class=backlight"
            "set"
            "10%-"
          ];
          _props.allow-when-locked = true;
        };

        # Window management
        "Mod+O" = {
          toggle-overview = { };
          _props.repeat = false;
        };
        "Mod+Q" = {
          close-window = { };
          _props.repeat = false;
        };

        # Focus movement
        "Mod+Left".focus-column-left = { };
        "Mod+Down".focus-window-down = { };
        "Mod+Up".focus-window-up = { };
        "Mod+Right".focus-column-right = { };
        "Mod+H".focus-column-left = { };
        "Mod+J".focus-window-down = { };
        "Mod+K".focus-window-up = { };
        "Mod+L".focus-column-right = { };

        # Window movement
        "Mod+Ctrl+Left".move-column-left = { };
        "Mod+Ctrl+Down".move-window-down = { };
        "Mod+Ctrl+Up".move-window-up = { };
        "Mod+Ctrl+Right".move-column-right = { };
        "Mod+Ctrl+H".move-column-left = { };
        "Mod+Ctrl+J".move-window-down = { };
        "Mod+Ctrl+K".move-window-up = { };
        "Mod+Ctrl+L".move-column-right = { };

        # Column focus
        "Mod+Home".focus-column-first = { };
        "Mod+End".focus-column-last = { };
        "Mod+Ctrl+Home".move-column-to-first = { };
        "Mod+Ctrl+End".move-column-to-last = { };

        # Monitor focus
        "Mod+Shift+Left".focus-monitor-left = { };
        "Mod+Shift+Down".focus-monitor-down = { };
        "Mod+Shift+Up".focus-monitor-up = { };
        "Mod+Shift+Right".focus-monitor-right = { };
        "Mod+Shift+H".focus-monitor-left = { };
        "Mod+Shift+J".focus-monitor-down = { };
        "Mod+Shift+K".focus-monitor-up = { };
        "Mod+Shift+L".focus-monitor-right = { };

        # Monitor movement
        "Mod+Shift+Ctrl+Left".move-column-to-monitor-left = { };
        "Mod+Shift+Ctrl+Down".move-column-to-monitor-down = { };
        "Mod+Shift+Ctrl+Up".move-column-to-monitor-up = { };
        "Mod+Shift+Ctrl+Right".move-column-to-monitor-right = { };
        "Mod+Shift+Ctrl+H".move-column-to-monitor-left = { };
        "Mod+Shift+Ctrl+J".move-column-to-monitor-down = { };
        "Mod+Shift+Ctrl+K".move-column-to-monitor-up = { };
        "Mod+Shift+Ctrl+L".move-column-to-monitor-right = { };

        # Workspace navigation
        "Mod+Page_Down".focus-workspace-down = { };
        "Mod+Page_Up".focus-workspace-up = { };
        "Mod+U".focus-workspace-down = { };
        "Mod+I".focus-workspace-up = { };
        "Mod+Ctrl+Page_Down".move-column-to-workspace-down = { };
        "Mod+Ctrl+Page_Up".move-column-to-workspace-up = { };
        "Mod+Ctrl+U".move-column-to-workspace-down = { };
        "Mod+Ctrl+I".move-column-to-workspace-up = { };

        # Workspace movement
        "Mod+Shift+Page_Down".move-workspace-down = { };
        "Mod+Shift+Page_Up".move-workspace-up = { };
        "Mod+Shift+U".move-workspace-down = { };
        "Mod+Shift+I".move-workspace-up = { };

        # Mouse wheel
        "Mod+WheelScrollDown" = {
          focus-workspace-down = { };
          _props.cooldown-ms = 150;
        };
        "Mod+WheelScrollUp" = {
          focus-workspace-up = { };
          _props.cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollDown" = {
          move-column-to-workspace-down = { };
          _props.cooldown-ms = 150;
        };
        "Mod+Ctrl+WheelScrollUp" = {
          move-column-to-workspace-up = { };
          _props.cooldown-ms = 150;
        };

        "Mod+WheelScrollRight".focus-column-right = { };
        "Mod+WheelScrollLeft".focus-column-left = { };
        "Mod+Ctrl+WheelScrollRight".move-column-right = { };
        "Mod+Ctrl+WheelScrollLeft".move-column-left = { };

        "Mod+Shift+WheelScrollDown".focus-column-right = { };
        "Mod+Shift+WheelScrollUp".focus-column-left = { };
        "Mod+Ctrl+Shift+WheelScrollDown".move-column-right = { };
        "Mod+Ctrl+Shift+WheelScrollUp".move-column-left = { };

        # Workspace by index
        "Mod+1".focus-workspace = 1;
        "Mod+2".focus-workspace = 2;
        "Mod+3".focus-workspace = 3;
        "Mod+4".focus-workspace = 4;
        "Mod+5".focus-workspace = 5;
        "Mod+6".focus-workspace = 6;
        "Mod+7".focus-workspace = 7;
        "Mod+8".focus-workspace = 8;
        "Mod+9".focus-workspace = 9;
        "Mod+Ctrl+1".move-column-to-workspace = 1;
        "Mod+Ctrl+2".move-column-to-workspace = 2;
        "Mod+Ctrl+3".move-column-to-workspace = 3;
        "Mod+Ctrl+4".move-column-to-workspace = 4;
        "Mod+Ctrl+5".move-column-to-workspace = 5;
        "Mod+Ctrl+6".move-column-to-workspace = 6;
        "Mod+Ctrl+7".move-column-to-workspace = 7;
        "Mod+Ctrl+8".move-column-to-workspace = 8;
        "Mod+Ctrl+9".move-column-to-workspace = 9;

        # Column management
        "Mod+BracketLeft".consume-or-expel-window-left = { };
        "Mod+BracketRight".consume-or-expel-window-right = { };
        "Mod+Comma".consume-window-into-column = { };
        "Mod+Period".expel-window-from-column = { };

        # Size adjustment
        "Mod+R".switch-preset-column-width = { };
        "Mod+Shift+R".switch-preset-window-height = { };
        "Mod+Ctrl+R".reset-window-height = { };
        "Mod+F".maximize-column = { };
        "Mod+Shift+F".fullscreen-window = { };
        "Mod+Ctrl+F".expand-column-to-available-width = { };

        "Mod+C".center-column = { };
        "Mod+Ctrl+C".center-visible-columns = { };

        "Mod+Minus".set-column-width = "-10%";
        "Mod+Equal".set-column-width = "+10%";
        "Mod+Shift+Minus".set-window-height = "-10%";
        "Mod+Shift+Equal".set-window-height = "+10%";

        # Floating
        "Mod+V".toggle-window-floating = { };
        "Mod+Shift+V".switch-focus-between-floating-and-tiling = { };

        # Tabbed display
        "Mod+W".toggle-column-tabbed-display = { };

        # Screenshots
        "Print".screenshot = { };
        "Ctrl+Print".screenshot-screen = { };
        "Alt+Print".screenshot-window = { };

        # System
        "Mod+Escape" = {
          toggle-keyboard-shortcuts-inhibit = { };
          _props.allow-inhibiting = false;
        };
        "Mod+Shift+E".quit = { };
        "Ctrl+Alt+Delete".quit = { };
        "Mod+Shift+P".power-off-monitors = { };
      };
    };
  };
}
