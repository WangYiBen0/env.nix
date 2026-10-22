{
  lib,
  config,
  ...
}:

lib.mkIf config.machine.modules.editor.enable {
  programs.nixvim = {
    enable = true;

    withNodeJs = true;
    withPerl = true;
    withPython3 = true;
    withRuby = true;

    viAlias = true;
    vimAlias = true;
    defaultEditor = true;

    # `cjk` is Neovim's built-in pseudo-dictionary: runs of CJK characters are
    # skipped by the spell checker instead of being reported as one huge
    # misspelled word.  The upstream nixvim profile already defines
    # `opts.spelllang = [ "en" ]`, and `opts.*` does not merge across
    # definitions (it is a plain conflicting value), so overriding it needs
    # `mkForce` rather than a second definition.
    opts.spelllang = lib.mkForce [
      "en"
      "cjk"
    ];
  };
}
