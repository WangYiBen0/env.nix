{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

lib.mkIf config.machine.profiles.desktop {
  home.packages =
    (with pkgs; [
      maple-mono.NF-CN
      noto-fonts-cjk-sans
      source-han-serif
      smiley-sans
      lxgw-wenkai
      lxgw-wenkai-screen
      lxgw-neoxihei
      lxgw-neozhisong
      lxgw-zhenkai
      zhuque-fangsong
    ])
    ++ (with inputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}; [
      sf-pro
      sf-mono
      ny
    ]);

  fonts = {
    fontconfig = {
      enable = true;
      defaultFonts = {
        serif = [
          "New York"
          "LXGW Neo ZhiSong"
          "Source Han Serif SC"
        ];
        sansSerif = [
          "SF Pro Display"
          "LXGW Neo XiHei"
          "Noto Sans CJK SC"
        ];
        monospace = [
          "Maple Mono NF CN"
          "SF Mono"
        ];
        emoji = [
          "Noto Color Emoji"
        ];
      };

      configFile = {
        winChsFontAliases = {
          enable = true;
          label = "windows-chinese-font-aliases";
          priority = 60;
          text = ''
            <?xml version='1.0'?>

            <!-- Linked by Home Manager. -->

            <!DOCTYPE fontconfig SYSTEM 'urn:fontconfig:fonts.dtd'>
            <fontconfig>
            <description>Substitute common Windows Chinese font names (and their GB2312/GBK/ExtB variants) with open-source equivalents</description>

              <!--
                用 compare="contains" 做子串匹配，
                一条规则即可覆盖 宋体_GB2312 / SimSun-ExtB 之类的变体，
                避免逐个枚举。match 在 alias 之前解析，
                binding="strong" 保证优先级高于文档内嵌字体请求。
              -->

              <!-- 黑体 / SimHei / Microsoft YaHei 系列 (Sans-serif) -->
              <match target="pattern">
                <test name="family" compare="contains"><string>雅黑</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Noto Sans CJK SC</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>YaHei</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Noto Sans CJK SC</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>黑体</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW Neo XiHei</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>SimHei</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW Neo XiHei</string>
                </edit>
              </match>

              <!-- 宋体 / SimSun (Serif) -->
              <match target="pattern">
                <test name="family" compare="contains"><string>宋体</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW Neo ZhiSong</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>SimSun</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW Neo ZhiSong</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>NSimSun</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW Neo ZhiSong</string>
                </edit>
              </match>

              <!-- 楷体 / KaiTi -->
              <match target="pattern">
                <test name="family" compare="contains"><string>楷体</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW ZhenKai GB</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>KaiTi</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>LXGW ZhenKai GB</string>
                </edit>
              </match>

              <!-- 仿宋 / FangSong -->
              <match target="pattern">
                <test name="family" compare="contains"><string>仿宋</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Zhuque FangSong (technical preview)</string>
                </edit>
              </match>

              <match target="pattern">
                <test name="family" compare="contains"><string>FangSong</string></test>
                <edit name="family" mode="prepend" binding="strong">
                  <string>Zhuque FangSong (technical preview)</string>
                </edit>
              </match>

            </fontconfig>
          '';
        };
      };
    };
  };

  home.activation.rebuildFontCache = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.fontconfig}/bin/fc-cache --force --really-force
  '';
}
