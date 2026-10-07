{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine.modules.honk;

  # The native API block is rendered as plain text and appended to the main
  # config instead of living in config.d/: honk resolves `include` against the
  # *canonical* path of the config file, and /etc/honk/config.dae is a symlink
  # into /nix/store, so a sibling config.d/ would silently never match.
  apiConfigText = ''
    experimental {
        native_api {
            enabled: true
            listen: '${cfg.api.listen}'
            config_write: ${lib.boolToString cfg.api.configWrite}
            ui: '${pkgs.doona}/share/doona'
            ${lib.optionalString cfg.api.passwordAuth "password_auth: true"}
            ${lib.optionalString (cfg.api.secret != null) "secret: '${cfg.api.secret}'"}
        }
    }
  '';

  mainConfig = pkgs.writeText "honk-config.dae" (cfg.settings + "\n" + apiConfigText);
in
{
  # `enable` lives in modules/common/options.nix, alongside every other module.
  options.machine.modules.honk = {
    settings = lib.mkOption {
      type = lib.types.lines;
      default = ''
        global {
            wan_interface: auto
            data_dir: '/var/lib/honk'
        }

        routing {
            fallback: direct
        }
      '';
      example = ''
        routing {
            domain_suffix: ('geosite:cn', 'geosite:geolocation-!cn')
            fallback: direct
        }
      '';
      description = ''
        honk's main configuration file, in dae syntax. Written to
        `/etc/honk/config.dae`. Nodes, groups, routing and DNS go here.
      '';
    };

    api = {
      listen = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:9527";
        description = ''
          Address honk's native API and the doona web UI bind to. Use a LAN
          address to reach the UI at `/ui/` from other devices; the default
          only accepts connections from the machine itself.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 9527;
        description = "Port allowed through the firewall for the API and web UI.";
      };

      passwordAuth = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Sign in with an administrator account created in the UI on first
          use. Set to `false` and provide `secret` for token mode.
        '';
      };

      secret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Shared API token. Mutually exclusive with `passwordAuth`.
        '';
      };

      configWrite = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Let the UI edit honk's configuration, nodes and subscriptions.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.api.passwordAuth && cfg.api.secret != null);
        message = "machine.modules.honk.api: passwordAuth and secret are mutually exclusive.";
      }
      {
        assertion = cfg.api.passwordAuth || cfg.api.secret != null;
        message = "machine.modules.honk.api: enable passwordAuth or set secret.";
      }
    ];

    environment = {
      systemPackages = [ pkgs.doona ];

      etc."honk/config.dae".source = mainConfig;
    };

    systemd = {
      # honk needs the config directory and data directory writable by root only.
      tmpfiles.rules = [
        "d /etc/honk 0700 root root -"
        "d /var/lib/honk 0700 root root -"
      ];

      # honk runs as root: it attaches eBPF programs, creates the dae0 link and
      # the daens namespace, and adjusts sysctls. honk reads its config once at
      # startup, so a plain /etc change would never reach the running instance;
      # embedding the config hash in the unit makes nixos-rebuild restart honk
      # whenever the configuration changes.
      services.honk = {
        description = "honk transparent proxy engine";
        documentation = [ "https://github.com/daeuniverse/honk" ];

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        restartTriggers = [ mainConfig ];

        # honk pins eBPF maps under /sys/fs/bpf.
        unitConfig.RequiresMountsFor = [
          "/sys/fs/bpf"
          "/var/lib/honk"
        ];

        serviceConfig = {
          Type = "notify";
          ExecStart = lib.getExe pkgs.honk;
          ExecReload = "${pkgs.honk}/bin/honk-core reload";
          Restart = "on-failure";
          RestartSec = "2s";
          TimeoutStartSec = "180s";
          TimeoutStopSec = "30s";
          LimitNOFILE = "1048576";
          LimitMEMLOCK = "infinity";
          # No NoNewPrivileges and no capability bounding: startup needs BPF,
          # NET_ADMIN, namespace, mount and sysctl privileges.
          UMask = "0077";
        };

        environment = {
          RUST_LOG = "info";
          MIMALLOC_PURGE_DELAY = "0";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.api.port ];
  };
}
