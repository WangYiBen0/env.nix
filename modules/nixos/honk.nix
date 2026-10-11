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

  # base.dae: user-tunable settings + routing, seeded once so routing edits
  # made in doona survive restarts. api.dae: the native_api block, owned by
  # Nix and reinstalled on every start. doona refuses to edit any file that
  # contains native_api or clash_api, so the API block must live in its own
  # include file or the UI's simple-mode rule editing stays disabled.
  baseConfig = pkgs.writeText "honk-base.dae" cfg.settings;
  apiConfig = pkgs.writeText "honk-api.dae" apiConfigText;
  entrySeed = pkgs.writeText "honk-entry.dae" "include {\n    'base.dae'\n}\ninclude {\n    'api.dae'\n}\n";
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
        `/var/lib/honk/base.dae` and seeded there once; delete
        `/var/lib/honk/.base-seeded` to re-seed from a later rebuild. Nodes,
        groups, routing and DNS go here, edited through the doona UI; the
        control plane (native_api) lives separately in `api.dae` so doona
        is allowed to rewrite this file.
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
      # doona is the web UI; pkgs.honk provides the honk-core CLI (status,
      # `honk-core reload`, debugging) for interactive use.
      systemPackages = [
        pkgs.doona
        pkgs.honk
      ];
    };

    systemd = {
      # honk needs the data directory writable by root only.
      tmpfiles.rules = [
        "d /var/lib/honk 0700 root root -"
      ];

      # honk runs as root: it attaches eBPF programs, creates the dae0 link and
      # the daens namespace, and adjusts sysctls. honk reads its config once at
      # startup, so a plain file change would never reach the running instance;
      # embedding the config hashes in the unit makes nixos-rebuild restart
      # honk whenever the Nix-owned configuration changes. File layout:
      #   config.dae  entry, seeded once, UI-owned (subscriptions live here)
      #   base.dae    seeded once, UI-editable settings + routing
      #   api.dae     force-installed every start, Nix-owned control plane
      services.honk-core = {
        description = "honk transparent proxy engine";
        documentation = [ "https://github.com/daeuniverse/honk" ];

        wantedBy = [ "multi-user.target" ];

        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        restartTriggers = [
          baseConfig
          apiConfig
        ];

        # honk pins eBPF maps under /sys/fs/bpf.
        unitConfig.RequiresMountsFor = [
          "/sys/fs/bpf"
          "/var/lib/honk"
        ];

        serviceConfig = {
          Type = "notify";
          ExecStart = "${lib.getExe pkgs.honk} -c /var/lib/honk/config.dae";
          ExecStartPre = pkgs.writeShellScript "honk-prestart" ''
            set -eu
            # The data directory can disappear under a live unit (state
            # experiments, manual cleanup); recreate it here instead of
            # wedging ExecStartPre on a missing parent directory.
            mkdir -p /var/lib/honk

            # Control plane: Nix owns it, reinstall unconditionally.
            install -Dm0600 ${apiConfig} /var/lib/honk/api.dae

            # base.dae and the entry file are seeded only once (or when
            # missing) so doona's edits survive restarts. The first start
            # with no marker replaces whatever is there — that one
            # replacement doubles as the migration path from the old
            # single-file layout.
            if [ ! -e /var/lib/honk/.base-seeded ]; then
              install -Dm0600 ${baseConfig} /var/lib/honk/base.dae
              touch /var/lib/honk/.base-seeded
            fi
            if [ ! -e /var/lib/honk/config.dae ]; then
              install -Dm0600 ${entrySeed} /var/lib/honk/config.dae
            elif ! grep -q "'api.dae'" /var/lib/honk/config.dae; then
              # Entries written by the old layout only include base.dae;
              # honk accepts multiple include blocks, so append one.
              printf "\ninclude {\n    'api.dae'\n}\n" >> /var/lib/honk/config.dae
            fi
          '';
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
