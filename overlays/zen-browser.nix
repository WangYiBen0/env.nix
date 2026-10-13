inputs: final: _prev:
let
  zen = inputs.zen-browser.packages.${final.stdenv.hostPlatform.system};
in
{
  zen-browser = zen.default;
  zen-browser-beta = zen.beta;
  zen-browser-twilight = zen.twilight;
}
