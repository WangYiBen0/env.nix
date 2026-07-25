{ self, ... }: {
  imports = self.lib.scanNixFiles ./.;
}
