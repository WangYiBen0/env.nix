{
  programs.nixvim = {
    enable = true;

    withNodeJs = true;
    withPerl = true;
    withPython3 = true;
    withRuby = true;

    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
}
