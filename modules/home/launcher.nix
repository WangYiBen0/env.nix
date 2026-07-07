{
  config,
  pkgs,
  lib,
  ...
}:

lib.mkIf config.machine.profiles.desktop {
  programs.anyrun = {
    enable = false;
    config = {
      # Position/size fields use an enum for the value, it can be either:
      # Absolute(n): The absolute value in pixels
      # Fraction(n): A fraction of the width or height of the full screen (depends on exclusive zones and the settings related to them) window respectively

      # The horizontal position, adjusted so that Relative(0.5) always centers the runner
      x.fraction = 0.5;
      # The vertical position, works the same as `x`
      y.absolute = 0;
      # The width of the runner
      width.absolute = 800;
      # The minimum height of the runner, the runner will expand to fit all the entries
      # NOTE: If this is set to 0, the window will never shrink after being expanded
      height.absolute = 1;

      # Hide match and plugin info icons
      hideIcons = false;

      # ignore exclusive zones, f.e. Waybar
      ignoreExclusiveZones = false;

      # Layer shell layer: Background, Bottom, Top, Overlay
      layer = "overlay";

      # Hide the plugin info panel
      hidePluginInfo = false;

      # Close window when a click outside the main box is received
      closeOnClick = true;

      # Show search results immediately when Anyrun starts
      showResultsImmediately = true;

      # Limit amount of entries shown in total
      maxEntries = null;

      # List of plugins to be loaded by default, can be specified with a relative path to be loaded from the
      # `<anyrun config dir>/plugins` directory or with an absolute path to just load the file the path points to.
      #
      # The order of plugins here specifies the order in which they appear
      # in the results. As in it works as a priority for the plugins.
      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/libsymbols.so"
        "${pkgs.anyrun}/lib/libshell.so"
        "${pkgs.anyrun}/lib/libtranslate.so"
      ];

      # waiting for https://github.com/nix-community/home-manager/issues/8590
      #
      # keybinds = [
      #   {
      #     key = "Return";
      #     action = "Select";
      #   }
      #   {
      #     key = "Up";
      #     action = "Up";
      #   }
      #   {
      #     key = "Down";
      #     action = "Down";
      #   }
      #   {
      #     key = "ISO_Left_Tab";
      #     action = "Up";
      #     shift = true;
      #   }
      #   {
      #     key = "Tab";
      #     action = "Down";
      #   }
      #   {
      #     key = "Escape";
      #     action = "Close";
      #   }
      # ];
    };

    extraConfigFiles = {
      "shell.ron".text = ''
        Config(
          prefix: "",
          shell: None,
        )
      '';
      "keybinds.ron".text = ''
        Config(
          keybinds: [
           Keybind(
             key: "Return",
             action: Select,
           ),
           Keybind(
             key: "Up",
             action: Up,
           ),
           Keybind(
             key: "Down",
             action: Down,
           ),
           Keybind(
             key: "ISO_Left_Tab",
             action: Up,
             shift: true,
           ),
           Keybind(
             key: "Tab",
             action: Down,
           ),
           Keybind(
             key: "Escape",
             action: Close,
           ),
          ],
        )
      '';
    };
  };

  programs.fuzzel = {
    enable = true;
  };
}
