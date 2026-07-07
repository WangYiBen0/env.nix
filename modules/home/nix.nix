{
  # nix.package 不在这里定义，避免 NixOS module 模式下和系统配置冲突
  # standalone 模式下在 outputs/default.nix 里单独设置
  nix.settings = { };

  catppuccin.cache.enable = true;
}
