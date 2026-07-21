{ inputs, ... }: {
  nixpkgs.overlays = [ (import ../../overlays inputs) ];
}
