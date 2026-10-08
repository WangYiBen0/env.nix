{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine.modules.honk;

  # Native API block appended to the Nix-owned base config. The UI edits
  # /var/lib/honk/config.dae (an entry file) which `include`s 'base.dae'; the
  # entry lives in a writable directory so the config coordinator can write to
  # it (fixes 503 "Configuration coordinator is unavailable" when writing
  # through a symlink into /nix/store).
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

  baseConfig = pkgs.writeText "honk-base.dae" (cfg.settings + "\n" + apiConfigText);
  entrySeed = pkgs.writeText "honk-entry.dae" "include {\n    'base.dae'\n}\n";
in
{
  # `enable` lives in modules/common/options.nix, alongside every other module.
  options.machine.modules.honk = {
    settings = lib.mkOption {
      type = lib.types.lines;
      # nfqueue_enable is pinned instead of left at honk's default: when the
      # NFQUEUE netlink family is unavailable, honk downgrades the key in the
      # running config at startup but leaves the file at `true`. That drift is
      # restart-required, so every managed config write (adding a subscription
      # in doona, saving) is then rejected with 422 "Configuration validation
      # failed". Staging cannot work on this machine anyway; pinning the file
      # to the value honk actually runs with removes the drift.
      default = ''
        global {
            wan_interface: auto
            data_dir: '/var/lib/honk'
            nfqueue_enable: false
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
        honk's base configuration in dae syntax (Nix-owned). Rendered to
        `/var/lib/honk/base.dae` and force-installed on each honk start.
        Nodes, groups, routing and DNS go here. The doona UI writes to
        `/var/lib/honk/config.dae` (entry file that `include`s base) so it
        survives rebuilds.
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
    };

    # Seed the UI-writable entry file once. It only contains `include`, so
    # rebuilds never need to touch it again: honk appends subscription/node
    # edits made in doona directly into this file, and it survives rebuilds
    # because it lives outside /nix/store.
    system.activationScripts.honkEntry = lib.stringAfter [ "etc" ] ''
      mkdir -p /var/lib/honk
      chmod 0700 /var/lib/honk
      if [ ! -e /var/lib/honk/config.dae ]; then
        install -m 0600 ${entrySeed} /var/lib/honk/config.dae
      fi
    '';

    systemd = {
      # honk needs the data directory writable by root only.
      tmpfiles.rules = [
        "d /var/lib/honk 0700 root root -"
      ];

      # honk runs as root: it attaches eBPF programs, creates the dae0 link and
      # the daens namespace, and adjusts sysctls. honk reads its config once at
      # startup, so a plain file change would never reach the running instance;
      # embedding the base config hash in the unit makes nixos-rebuild restart
      # honk whenever the Nix-owned configuration changes. ExecStartPre
      # force-installs base.dae (the store copy is the truth for the
      # declarative half) while config.dae stays UI-owned and untouched.
      services.honk = {
        description = "honk transparent proxy engine";
        documentation = [ "https://github.com/daeuniverse/honk" ];

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        restartTriggers = [ baseConfig ];

        # honk pins eBPF maps under /sys/fs/bpf.
        unitConfig.RequiresMountsFor = [
          "/sys/fs/bpf"
          "/var/lib/honk"
        ];

        serviceConfig = {
          Type = "notify";
          ExecStart = "${lib.getExe pkgs.honk} -c /var/lib/honk/config.dae";
          ExecStartPre = "${pkgs.coreutils}/bin/install -m 0600 ${baseConfig} /var/lib/honk/base.dae";
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
