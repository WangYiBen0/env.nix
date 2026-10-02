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
  inherit (allPackages.agents) deepseek-harness dsh-tui miyu;
  inherit (allPackages.applications)
    cele-mod
    dingtalk
    loenn
    linuxqq
    ;
}
