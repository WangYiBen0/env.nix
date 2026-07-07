{ lib, myLib, ... }:
let
  users = myLib.listSubDir ./.;
in
{
  imports = lib.concatMap (username: [
    ./${username}/nixos-module
  ]) users;

  home-manager.users = lib.genAttrs users (username: ./${username});
}
