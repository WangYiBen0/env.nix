{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.machine.modules.accesser;

  # Accesser reads config.toml, rules.toml and rules/*.toml from its working
  # directory at import time (accesser/utils/setting.py), so the whole state
  # directory is both config and working directory. Root keys first, then the
  # two tables upstream's own config.toml defines; anything the user adds via
  # `extraConfig` must therefore start with its own table header (`[DNS]`, …),
  # which is exactly how upstream's rules.toml is laid out.
  configText = ''
    check_hostname = ${
      if cfg.checkHostname == "strict" then "\"strict\"" else lib.boolToString cfg.checkHostname
    }
    setproxy = false
    importca = false
    ipv6 = ${lib.boolToString cfg.ipv6}

    [log]
    loglevel = "${cfg.loglevel}"
    logfile = ""

    [server]
    address = "${cfg.address}"
    port = ${toString cfg.port}
    pac_host = "${cfg.pacHost}"
  ''
  + lib.optionalString (cfg.extraConfig != "") "\n${cfg.extraConfig}\n";

  configFile = pkgs.writeText "accesser-config.toml" configText;

  rulesFile = pkgs.writeText "accesser-rules.toml" cfg.extraRules;

  stateDir = "/var/lib/accesser";
in
{
  # `enable` lives in modules/common/options.nix, alongside every other module.
  options.machine.modules.accesser = {
    port = lib.mkOption {
      type = lib.types.port;
      default = 7654;
      description = ''
        Port the local proxy and its PAC/certificate endpoints listen on.
        This is also the port written into the PAC file.
      '';
    };

    address = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the proxy binds to. The default only accepts connections from
        this machine; a LAN address (or `0.0.0.0`) lets other devices use it as
        their proxy, which also means they must trust the generated CA.
      '';
    };

    pacHost = lib.mkOption {
      type = lib.types.str;
      default = cfg.address;
      defaultText = lib.literalExpression "config.machine.modules.accesser.address";
      description = ''
        Host written into the PAC file as the proxy address. Set this to the
        machine's LAN IP when `address` is `0.0.0.0`.
      '';
    };

    checkHostname = lib.mkOption {
      type = lib.types.either lib.types.bool (lib.types.enum [ "strict" ]);
      default = true;
      description = ''
        Certificate hostname verification. `true` accepts a loose match (the
        last two labels must agree), `"strict"` is standard RFC 2818 matching,
        `false` disables verification entirely. Per-domain overrides go in
        `extraConfig` under `[cert_verify]`.
      '';
    };

    ipv6 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Prefer AAAA records when resolving upstream hosts.";
    };

    loglevel = lib.mkOption {
      type = lib.types.enum [
        "CRITICAL"
        "ERROR"
        "WARNING"
        "INFO"
        "DEBUG"
      ];
      default = "INFO";
      description = "Log level; the service logs to the journal.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      example = ''
        [DNS]
        nameserver = [ "https://77.88.8.8/dns-query" ]

        [hosts]
        "dns.adguard-dns.com" = "94.140.14.14"
      '';
      description = ''
        Extra `config.toml` content, appended verbatim after the generated
        `[server]` table. Keys defined here win over `rules.toml` and over
        per-rule files, so this is the place for `[DNS]`, `[hosts]`,
        `[http_redirect]`, `[alter_hostname]` and `[cert_verify]` overrides.
        Because TOML has no way to reopen a table, every entry must live under
        a table header.
      '';
    };

    extraRules = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Additional routing/TLS rules, installed to
        `${stateDir}/rules/nixos.toml`. Rules in this directory outrank the
        upstream-managed `rules.toml`, which Accesser keeps refreshing on its
        own, but lose to `config.toml`. Table layout is the same as
        upstream's `rules.toml`.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = cfg.address != "127.0.0.1" && cfg.address != "::1";
      defaultText = lib.literalExpression ''config.machine.modules.accesser.address != "127.0.0.1"'';
      description = "Open the proxy port in the firewall so other devices can use it.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.accesser ];

    systemd = {
      services.accesser = {
        description = "Accesser local HTTPS proxy (SNI RST workaround)";
        documentation = [ "https://github.com/URenko/Accesser" ];

        wantedBy = [ "multi-user.target" ];
        wants = [ "network-online.target" ];
        after = [ "network-online.target" ];

        # The config is only read when the process starts, so a changed
        # configuration has to restart the unit rather than reload it.
        restartTriggers = [
          configFile
        ]
        ++ lib.optional (cfg.extraRules != "") rulesFile;

        serviceConfig = {
          Type = "simple";

          # Accesser resolves relative paths (config.toml, rules.toml, rules/)
          # against the working directory, and generates the root CA in the
          # state directory. `--state-dir` pins the latter so it does not
          # depend on $HOME. The proxy itself needs no privileges: it binds an
          # unprivileged port and only touches its own state.
          DynamicUser = true;
          WorkingDirectory = stateDir;
          StateDirectory = "accesser";
          StateDirectoryMode = "0700";
          ExecStart = "${lib.getExe pkgs.accesser} --state-dir ${stateDir} --notsetproxy --notimportca";

          # config.toml is Nix-owned and reinstalled on every start; rules.toml
          # is upstream's and is seeded/refreshed by Accesser itself, so it is
          # deliberately left alone here.
          ExecStartPre = pkgs.writeShellScript "accesser-prestart" (
            ''
              set -eu
              install -Dm0600 ${configFile} ${stateDir}/config.toml
              install -dm0700 ${stateDir}/rules
            ''
            + lib.optionalString (cfg.extraRules != "") ''
              install -Dm0600 ${rulesFile} ${stateDir}/rules/nixos.toml
            ''
          );

          Restart = "on-failure";
          RestartSec = "2s";

          # The proxy terminates TLS locally but needs nothing beyond its state
          # directory and the network.
          UMask = "0077";
          NoNewPrivileges = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
            "AF_NETLINK"
          ];
        };
      };
    };

    networking.firewall.allowedTCPPorts = lib.optional cfg.openFirewall cfg.port;
  };
}
