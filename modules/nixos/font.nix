{
  lib,
  config,
  pkgs,
  ...
}:
{
  config = lib.mkIf config.machine.profiles.desktop {
    fonts = {
      enableDefaultPackages = true;

      fontDir.enable = true;

      packages = with pkgs; [
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-cjk-serif
        noto-fonts-color-emoji
        maple-mono.NF-CN
        jetbrains-mono
        nerd-fonts.symbols-only
        nerd-fonts.liberation
        liberation_ttf
        inter
        winePackages.fonts
        texlivePackages.fandol
        source-han-sans
        source-han-serif
        source-han-mono
        source-code-pro
        source-sans
        source-serif
      ];

      fontconfig = {
        enable = true;
        defaultFonts = {
          sansSerif = [
            "Noto Sans CJK SC"
            "Symbols Nerd Font"
          ];
          serif = [
            "Noto Serif CJK SC"
            "Symbols Nerd Font"
          ];
          monospace = [
            "Maple Mono NF CN"
            "JetBrains Mono"
            "Symbols Nerd Font Mono"
          ];
          emoji = [ "Noto Color Emoji" ];
        };

        localConf = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
          <fontconfig>

            <match target="pattern">
              <test qual="any" name="family">
                <string>sans-serif</string>
              </test>
              <edit name="family" mode="prepend" binding="strong">
                <string>Symbols Nerd Font</string>
              </edit>
            </match>

            <match target="pattern">
              <test qual="any" name="family">
                <string>serif</string>
              </test>
              <edit name="family" mode="prepend" binding="strong">
                <string>Symbols Nerd Font</string>
              </edit>
            </match>

          </fontconfig>
        '';
      };
    };
  };
}
