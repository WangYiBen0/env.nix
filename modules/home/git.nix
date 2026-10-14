{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.git.enable {
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "W1ngD1nGa5ter";
        email = "wangyiben1@outlook.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };
}
