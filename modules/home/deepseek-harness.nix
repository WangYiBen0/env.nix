{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine.modules.deepseek-harness;

  # The web profile binds a single concrete loopback address — wildcards are
  # rejected — and prints a tokenised launch URL to stdout on boot. `--no-open`
  # is required under systemd: there is no browser session to open, and without
  # it the profile would still be reaching for a default browser.
  args = [
    "--profile"
    "web"
    "--no-open"
    "--host"
    cfg.host
    "--port"
    (toString cfg.port)
  ];
in
{
  options.machine.modules.deepseek-harness = {
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the deepseek-harness web UI binds to. Like honk's API this must
        be one concrete local address; a wildcard such as 0.0.0.0 is rejected by
        the profile itself. Anything other than loopback exposes the launch token
        to the network, so widen it only behind a TLS proxy.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3080;
      description = "Port the deepseek-harness web UI listens on.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.user.services.deepseek-harness = {
      Unit = {
        Description = "deepseek-harness web UI";
        Documentation = [ "https://github.com/deepseek-ai/deepseek-harness" ];
        # PartOf ties the unit to the session: logging out stops it rather than
        # leaving an orphaned listener holding the port into the next login.
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe pkgs.deepseek-harness} ${lib.escapeShellArgs args}";
        Restart = "on-failure";
        # The profile mounts plugin layers and resolves the workspace on boot;
        # a fast restart loop on a genuinely transient failure is worse than
        # waiting a beat.
        RestartSec = "3s";
        TimeoutStopSec = "20s";

        # dsh resolves DSH_HOME from $HOME/.dsh, so the session's HOME is the
        # one thing that must be right. Wipe the rest: the unit inherits the
        # user manager's environment, and leftovers from an interactive shell
        # (proxies, stale DSH_HOME, locale overrides) make the service behave
        # differently from a fresh login.
        Environment = [ "DSH_HOME=%h/.dsh" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
