{ config, lib, ... }:

let
  links = {
    "桌面" = "desktop";
    "文档" = "documents";
    "下载" = "download";
    "音乐" = "music";
    "图片" = "pictures";
    "项目" = "projects";
    "模板" = "templates";
    "视频" = "videos";
    "公共" = "publicShare";
  };
in
lib.mkIf config.machine.modules.directory.enable {
  xdg.userDirs = {
    enable = true;
    # createDirectories = true; # 可能导致现有程序崩溃，造成大批量重启淹没终端输出
    setSessionVariables = true;
  };

  home.file = lib.mapAttrs (_chineseName: xdgKey: {
    source = config.lib.file.mkOutOfStoreSymlink config.xdg.userDirs.${xdgKey};
  }) links;
}
