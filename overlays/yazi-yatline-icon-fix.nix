_inputs: _final: prev: {
  yaziPlugins = prev.yaziPlugins // {
    yatline = prev.yaziPlugins.yatline.overrideAttrs (_oldAttrs: {
      postInstall = ''
        substituteInPlace $out/main.lua \
          --replace-fail 'hovered:icon().text' 'th.icon:match(hovered).text'
      '';
    });
  };
}
