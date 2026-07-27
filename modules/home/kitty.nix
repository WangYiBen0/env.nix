{ config, lib, ... }:

lib.mkIf config.machine.modules.kitty.enable {
  # Kitty 配置，Inspired by end-4
  programs.kitty = {
    enable = true;

    enableGitIntegration = true;

    settings = {
      # 字体设置
      font_family = "Maple Mono NF CN";
      font_size = 11.0;

      # 光标
      cursor_shape = "beam";
      cursor_trail = 5;

      # 窗口边距
      # window_margin_width = 21.75;
      # window_margin_width = 10;
      window_padding_width = 20;

      # 关闭确认
      confirm_os_window_close = 0;

      # 默认 shell
      shell = "fish";

      scrollback_pager = "nvim --cmd 'set eventignore=FileType' +'nnoremap q ZQ' +'call nvim_open_term(0, {})' +'set nomodified nolist' +'$' -";

      allow_remote_control = true;
      draw_minimal_borders = true;
      enable_audio_bell = false;
      update_check_interval = 0;
    };

    # 键盘快捷键
    keybindings = {
      # 复制
      "ctrl+c" = "copy_or_interrupt";

      # 搜索（使用自定义 kitten）
      "ctrl+f" =
        "launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id";
      "kitty_mod+f" =
        "launch --location=hsplit --allow-remote-control kitty +kitten search.py @active-kitty-window-id";

      # 滚动
      "page_up" = "scroll_page_up";
      "page_down" = "scroll_page_down";

      # 字体缩放
      "ctrl+plus" = "change_font_size all +1";
      "ctrl+equal" = "change_font_size all +1";
      "ctrl+kp_add" = "change_font_size all +1";
      "ctrl+minus" = "change_font_size all -1";
      "ctrl+underscore" = "change_font_size all -1";
      "ctrl+kp_subtract" = "change_font_size all -1";
      "ctrl+0" = "change_font_size all 0";
      "ctrl+kp_0" = "change_font_size all 0";
    };
  };

  xdg.configFile = {
    "kitty/scroll_mark.py".source = ./kitty/scroll_mark.py;
    "kitty/search.py".source = ./kitty/search.py;
  };

  # 确保 kitten 脚本可执行
  home.activation = {
    makeKittensExecutable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      chmod +x ${config.home.homeDirectory}/.config/kitty/kittens/*.py 2>/dev/null || true
    '';
  };
}
