{
  archive-manager = {
    npmName = "@michengai/dsh-archive-manager";
    # version = "latest";
  };
  opencode2dsh = {
    npmName = "@opencode2dsh/dsh-plugin";
    # version = "latest";
  };
  dsh-im = {
    npmName = "@xmanrui/dsh-im";
    # version = "latest";
  };
  background-by-model = {
    # version = "latest";
  };
  chat-import = {
    # version = "latest";
  };
  free-search = {
    # version = "latest";
  };
  pocket = {
    # version = "latest";
  };
  market = {
    npmName = "dshmarket";
    # version = "latest";
  };
  ops = {
    # version = "latest";
  };
  tool-normalizer = {
    # version = "latest";
  };
  whale-widget = {
    # version = "latest";
  };

  # tui: GitHub-source plugin, tracked by frozen commit. Declaring it here puts
  # it through the same generator path as every other plugin; rev/hash are
  # filled in by `update-plugin-lock`.
  tui = {
    github = {
      owner = "ccch1mneyyy";
      repo = "dsh-TUI";
    };
    fetchSubmodules = true;
    # The built package is the repository root itself
    # (@deepseek-harness-tui/dsh-tui; its package.json carries the version).
    # `compile` rather than `build`: `build` ends in a verification harness
    # that expects a live dsh installation. `nestedPnpmDir` names the vendored
    # submodule workspace `compile` installs internally — the generator probes
    # that nested store and pins it as `nestedPnpmDepsHash`, so the plugin
    # builds fully offline (this is what the old config could not do).
    nestedPnpmDir = "vendor/dsh-std";
    npmBuildScript = "compile";
  };
}
