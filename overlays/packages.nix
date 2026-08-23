_inputs: _final: prev:
let
  allPackages = prev.lib.filesystem.packagesFromDirectoryRecursive {
    inherit (prev) callPackage;
    directory = ../pkgs;
  };
in
allPackages
// {
  inherit (allPackages.fonts) lxgw-neozhisong lxgw-zhenkai zhuque-fangsong;
  inherit (allPackages.agent) miyu deepseek-harness dsh-tui;
}
