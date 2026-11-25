{
  config,
  lib,
  pkgs,
  ...
}:

# honk: an eBPF transparent-proxy engine with a native HTTP API and a web UI.
#
# This is a plain NixOS module on purpose — `services.honk-dae.*`, no
# `machine.*` reference — so it can be lifted into nixpkgs as-is. The only
# external input is the package that supplies `honk-core` and the `doona` web
# UI; both are options below, and the defaults assume the two by-name packages.
#
# The attribute is `honk-dae` and not `honk` because nixpkgs already spent that
# name: services.honk was the honk.me mail stack, removed in favour of its
# upstream successor, and nixos/modules/rename.nix still carries a
# mkRemovedOptionModule for it. Declaring options.services.honk here collides
# with that tombstone and fails with "The option `services.honk` ... would be a
# parent of the following options". The unit stays honk-core because that is
# the binary's own name, not this module's.
let
  cfg = config.services.honk-dae;

  # Routing and the control plane deliberately live in different files: doona
  # refuses to edit any file that contains an API block, so the native_api
  # settings must be in their own include or the UI's rule editing stays
  # disabled. api.dae is Nix-owned and reinstalled on every start; base.dae is
  # seeded once and thereafter belongs to the UI.
  apiConfig = pkgs.writeText "honk-api.dae" ''
    experimental {
        native_api {
            enabled: true
            listen: '${cfg.api.listen}'
            config_write: ${lib.boolToString cfg.api.configWrite}
            ui: '${cfg.doona}/share/doona'
            ${lib.optionalString cfg.api.passwordAuth "password_auth: true"}
            ${lib.optionalString (cfg.api.secret != null) "secret: '${cfg.api.secret}'"}
        }
    }
  '';

  # nfqueue_enable is pinned rather than left at honk's default: when the
  # NFQUEUE netlink family is unavailable, honk downgrades the key in the
  # running config at startup but leaves the file at `true`. That drift is
  # restart-required, so every managed config write (adding a subscription in
  # doona, saving) is then rejected with 422 "Configuration validation
  # failed". Pinning the file to the value honk actually runs with removes the
  # drift.
  baseConfig = pkgs.writeText "honk-base.dae" cfg.settings;

  # The entry file carries an *empty* routing block on purpose. doona's
  # outbound-mode switch does not send a config value: it splices a
  # top-priority `must` rule into the routing block of whichever source honk
  # reports with kind "main"
  # (crates/honk-core/src/native_api/config.rs, `"kind": if index==0 {"main"}`),
  # and index 0 is always the entry file. With routing and the API block both
  # living in includes, that text edit finds no routing block and the UI fails
  # with a "the main configuration has no routing section" error before it ever
  # reaches honk.
  #
  # An empty block is a safe placeholder because honk merges same-named
  # sections statement by statement rather than replacing them
  # (parser/mod.rs collects every `routing` segment into one list and
  # routing::parse_section walks them as a single body), so the rules in
  # base.dae still apply. Verified with honk-core v0.1.0-beta.7: two rules in
  # base.dae load as "0 groups, 2 routing rules" both with and without this
  # block. Do not move the rules here to "make it look right" — doona rewrites
  # this file, base.dae is the one seeded once and left alone.
  entrySeed = pkgs.writeText "honk-entry.dae" ''
    include {
        'base.dae'
    }
    include {
        'api.dae'
    }

    routing {
    }
  '';
in
{
  options.services.honk-dae = {
    enable = lib.mkEnableOption "honk transparent proxy engine";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.honk;
      defaultText = lib.literalExpression "pkgs.honk";
      description = "The honk package providing `honk-core`.";
    };

    doona = lib.mkOption {
      type = lib.types.package;
      default = pkgs.doona;
      defaultText = lib.literalExpression "pkgs.doona";
      description = "The doona web UI, served from its `share/doona` directory.";
    };

    settings = lib.mkOption {
      type = lib.types.lines;
      description = ''
        honk's base configuration in dae syntax. Rendered to
        `/var/lib/honk/base.dae` and seeded there once; delete
        `/var/lib/honk/.base-seeded` to re-seed from a later rebuild. Nodes,
        groups, routing and DNS go here, edited through the doona UI; the
        control plane (native_api) lives separately in `api.dae` so doona is
        allowed to rewrite this file.
      '';
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
    };

    api = {
      listen = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:9527";
        description = ''
          Address honk's native API and the doona web UI bind to. Use a LAN
          address to reach the UI at `/ui/` from other devices; the default only
          accepts connections from the machine itself.
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
          Sign in with an administrator account created in the UI on first use.
          Set to `false` and provide `secret` for token mode.
        '';
      };

      secret = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Shared API token. Mutually exclusive with `passwordAuth`.";
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
        message = "services.honk-dae.api: passwordAuth and secret are mutually exclusive.";
      }
      {
        assertion = cfg.api.passwordAuth || cfg.api.secret != null;
        message = "services.honk-dae.api: enable passwordAuth or set secret.";
      }
    ];

    environment.systemPackages = [
      cfg.doona
      cfg.package
    ];

    # honk needs the data directory writable by root only.
    systemd.tmpfiles.rules = [
      "d /var/lib/honk 0700 root root -"
    ];

    # honk runs as root: it attaches eBPF programs, creates the dae0 link and
    # the daens namespace, and adjusts sysctls. honk reads its config once at
    # startup, so a plain file change would never reach the running instance;
    # embedding the config hashes in the unit makes nixos-rebuild restart honk
    # whenever the Nix-owned configuration changes. File layout:
    #   config.dae  entry, seeded once, UI-owned (subscriptions live here)
    #   base.dae    seeded once, UI-editable settings + routing
    #   api.dae     force-installed every start, Nix-owned control plane
    systemd.services.honk-core = {
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
        ExecStart = "${lib.getExe cfg.package} -c /var/lib/honk/config.dae";
        ExecStartPre = pkgs.writeShellScript "honk-prestart" ''
          set -eu
          # The data directory can disappear under a live unit (state
          # experiments, manual cleanup); recreate it here instead of wedging
          # ExecStartPre on a missing parent directory.
          mkdir -p /var/lib/honk

          # Control plane: Nix owns it, reinstall unconditionally.
          install -Dm0600 ${apiConfig} /var/lib/honk/api.dae

          # base.dae and the entry file are seeded only once (or when missing)
          # so doona's edits survive restarts. The first start with no marker
          # replaces whatever is there — that one replacement doubles as the
          # migration path from the old single-file layout.
          if [ ! -e /var/lib/honk/.base-seeded ]; then
            install -Dm0600 ${baseConfig} /var/lib/honk/base.dae
            touch /var/lib/honk/.base-seeded
          fi
          if [ ! -e /var/lib/honk/config.dae ]; then
            install -Dm0600 ${entrySeed} /var/lib/honk/config.dae
          else
            # Entries written by the old layout only include base.dae; honk
            # accepts multiple include blocks, so append one.
            if ! grep -q "'api.dae'" /var/lib/honk/config.dae; then
              printf "\ninclude {\n    'api.dae'\n}\n" >> /var/lib/honk/config.dae
            fi
            # Entries seeded before the routing placeholder existed make
            # doona's outbound-mode switch fail; see the comment on entrySeed.
            if ! grep -qE '^[[:space:]]*routing[[:space:]]*\{' /var/lib/honk/config.dae; then
              printf "\nrouting {\n}\n" >> /var/lib/honk/config.dae
            fi
          fi
        '';
        ExecReload = "${cfg.package}/bin/honk-core reload";
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
        # honk ships jemalloc as its allocator, and jemalloc's purge delay is
        # spelled dirty_decay_ms. Zero returns freed pages to the OS as soon as
        # they are freed instead of holding them in the arena's dirty pages,
        # which is what the mimalloc setting this replaces did.
        MALLOC_CONF = "dirty_decay_ms:0";
      };
    };

    networking.firewall.allowedTCPPorts = [ cfg.api.port ];
  };
}
