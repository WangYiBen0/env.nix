{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.machine.modules.ironbar;

  entry = label: command: {
    type = "custom";
    inherit label;
    on_click = command;
  };

  tile = label: glyph: command: {
    type = "button";
    class = "cc-tile";
    on_click = command;
    widgets = [
      {
        type = "label";
        class = "cc-tile-icon";
        label = glyph;
      }
      {
        type = "label";
        class = "cc-tile-name";
        inherit label;
      }
    ];
  };

  barConfig = {
    name = "menubar";
    position = "top";
    layer = "top";
    height = 28;
    margin = {
      top = 0;
      bottom = 0;
      left = 0;
      right = 0;
    };
    anchor_to_edges = true;
    exclusive_zone = true;
    popup_gap = 4;

    start = [
      {
        type = "menu";
        name = "system-menu";
        label = null;
        label_icon = "nix-snowflake-white";
        label_icon_size = 17;
        app_icon_size = 16;
        center = [ ];
        start = [
          (entry "关于本机" "kinfocenter")
          (entry "系统设置…" "systemsettings")
          (entry "软件…" "plasma-discover")
        ];
        end = [
          (entry "强制退出…" "plasma-systemmonitor")
          (entry "锁定屏幕" "loginctl lock-session")
          (entry "睡眠" "systemctl suspend")
          (entry "重新启动…" "systemctl reboot")
          (entry "关机…" "systemctl poweroff")
        ];
      }
      {
        type = "focused";
        name = "focused-app";
        icon_size = 16;
        truncate = "end";
      }
    ];

    center = [ ];

    end = [
      {
        type = "tray";
        name = "tray";
        icon_size = 16;
        prefer_theme_icons = true;
      }
      {
        type = "bluetooth";
        name = "bluetooth";
        icon_size = 15;
        format = {
          connected = "󰂯";
          connected_battery = "󰂯";
          disabled = "󰂯";
          enabled = "󰂯";
        };
      }
      {
        type = "battery";
        name = "battery";
        icon_size = 16;
        show_label = false;
      }
      {
        type = "network_manager";
        name = "network";
        icon_size = 15;

        # NetworkManager publishes loopback, wifi-p2p and virtual interfaces
        # (netkit, bridges, ...) as devices too; a status bar only wants the
        # ones that carry real traffic.
        types_whitelist = [
          "ethernet"
          "wifi"
        ];
      }
      {
        type = "custom";
        name = "control-center";
        class = "control-center";
        bar = [
          {
            type = "button";
            name = "cc-btn";
            on_click = "popup:toggle";
            widgets = [
              {
                type = "label";
                name = "cc-icon";
                label = "󰘮";
              }
            ];
          }
        ];
        popup = [
          {
            type = "box";
            class = "cc-panel";
            orientation = "vertical";
            widgets = [
              {
                type = "box";
                class = "cc-row";
                orientation = "horizontal";
                widgets = [
                  (tile "Wi-Fi" "󰖩" "nmcli radio wifi toggle")
                  (tile "蓝牙" "󰂯" "bluetoothctl power on")
                ];
              }
              {
                type = "volume";
                name = "cc-volume";
                format = "{icon} {percentage}%";
                show_sources = false;
                show_monitors = false;
              }
            ];
          }
        ];
      }
      {
        type = "clock";
        name = "clock";
        format = "%m月%d日 周%a %H:%M";
        format_popup = "%Y年%m月%d日 %H:%M:%S";
      }
    ];
  }
  // lib.optionalAttrs (config.gtk.iconTheme.name != null) {
    icon_theme = config.gtk.iconTheme.name;
  };

  style = ''
    window.background {
      background-color: transparent;
    }

    * {
      font-family: "SF Pro Text", "SF Pro Display", "Helvetica Neue", sans-serif;
      font-size: 13px;
      border: none;
      border-radius: 0;
      box-shadow: none;
      margin: 0;
      padding: 0;
      min-height: 0;
    }

    #bar {
      background-color: rgba(28, 28, 30, 0.55);
      border-bottom: 1px solid rgba(255, 255, 255, 0.07);
      padding: 0 6px;
      color: #f2f2f7;
    }

    #start > * + *,
    #center > * + *,
    #end > * + * {
      margin-left: 2px;
    }

    button {
      padding: 1px 7px;
      border-radius: 5px;
      transition: background-color 120ms ease;
    }

    button:hover {
      background-color: rgba(255, 255, 255, 0.12);
    }

    button:active,
    button.active {
      background-color: rgba(255, 255, 255, 0.2);
    }

    label {
      color: #f2f2f7;
    }

    #system-menu button {
      padding: 1px 5px;
    }

    #focused-app {
      padding-left: 4px;
    }

    #focused-app .label {
      font-size: 13.5px;
      font-weight: 700;
    }

    #cc-icon {
      font-size: 15px;
    }

    popover {
      background-color: transparent;
      border: none;
      box-shadow: none;
      padding: 0;
    }

    popover > contents {
      background-color: rgba(32, 32, 35, 0.88);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 9px;
      box-shadow: none;
      padding: 5px;
    }

    .popup {
      padding: 6px;
    }

    .popup-menu .category,
    .popup-menu .application {
      padding: 4px 12px 4px 14px;
      border-radius: 5px;
      min-width: 190px;
    }

    .popup-menu .category:hover,
    .popup-menu .application:hover {
      background-color: rgba(255, 255, 255, 0.14);
    }

    .popup-menu .menu-title {
      font-weight: 700;
    }

    .popup-control-center .cc-panel {
      padding: 4px;
    }

    .popup-control-center .cc-row > * + * {
      margin-left: 8px;
    }

    .popup-control-center .cc-tile {
      padding: 9px 14px;
      border-radius: 11px;
      background-color: rgba(255, 255, 255, 0.12);
      min-height: 52px;
      min-width: 148px;
    }

    .popup-control-center .cc-tile:hover {
      background-color: rgba(255, 255, 255, 0.2);
    }

    .popup-control-center .cc-tile-icon {
      font-size: 20px;
    }

    .popup-control-center .cc-tile-name {
      font-size: 12.5px;
      margin-left: 11px;
    }
  '';
in
lib.mkIf cfg.enable {
  # nixpkgs' ironbar (0.19.1) does not build: its cargo build sets
  # LIBGIT2_NO_VENDOR but the derivation has no libgit2 in its buildInputs, so
  # libgit2-sys aborts with "no compatible system libgit2 could be found".
  # Upstream's own flake builds fine, so take the package from there instead of
  # waiting for the nixpkgs fix.
  home.packages = [ inputs.ironbar.packages.${pkgs.stdenv.hostPlatform.system}.default ];

  xdg.configFile = {
    "ironbar/config.json".source = (pkgs.formats.json { }).generate "ironbar-config.json" barConfig;
    "ironbar/style.css".text = style;
  };
}
