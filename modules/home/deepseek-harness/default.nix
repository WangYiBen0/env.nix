# DeepSeek Harness: the `web` profile and the unit that serves it.
#
# The split is deliberate:
#
#   * bundles and plugins are pinned derivations, so they live in Nix here;
#   * the patch layer is mutable state — dsh's web UI, model selection and
#     `dsh plugin` rewrite it — so it is only *seeded* once. After the first
#     write it belongs to dsh and to you, and no activation touches it again.
#
# Everything else (the package, the home, the unit, the profile plumbing) is
# the module's default, so it is not configured here.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  cfg = config.machine.modules.deepseek-harness;

  # Third-party plugins of the `web` profile. Everything except `tui` ships a
  # compiled tarball and builds without network access; `tui`'s own build
  # script runs a nested pnpm install that an offline store cannot satisfy, so
  # it is defined but not activated.
  plugins = import ./plugins.nix {
    inherit pkgs;
    inherit (inputs) deepseek-harnix;
  };
in
{
  options.machine.modules.deepseek-harness = {
    # `enable` lives in modules/common/options.nix, declared once for both the
    # NixOS and Home Manager trees.
    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the web UI binds to. Like honk's API this must be one concrete
        local address; a wildcard such as 0.0.0.0 is rejected by the profile
        itself. Anything other than loopback exposes the launch token to the
        network, so widen it only behind a TLS proxy.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3080;
      description = "Port the web UI listens on.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.dsh = {
      enable = true;
      # `package` stays at the module default: that default is this flake's own
      # build (`pkgs/deepseek-harness.nix`), which installs the shell
      # completions and is the build these profile plugins were pinned
      # against. `pkgs.deepseek-harness` would silently pick up whatever an
      # overlay put there — the nixpkgs derivation installs no completions.

      profiles.web = {
        # The shipped `web` template's own bundle list, so the composition is
        # not spelled out here.
        template = "web";
        plugins = lib.attrValues (removeAttrs plugins [ "tui" ]);
        # Seeded, not declared: dsh's web UI and model picker own
        # cordis.patch.yml after the first write.
        seedPatches = [
          {
            id = "agent-default-model";
            name = "@deepseek-ai/dsh-agent-default-model";
            config = {
              provider = "nvidia";
              model = "z-ai/glm-5.3-flash";
            };
          }
          {
            id = "llm-pi-ai";
            name = "@deepseek-ai/dsh-llm-pi-ai";
            config.providers = {
              nvidia.apiKeyEnv = "NVIDIA_API_KEY";
              google.apiKeyEnv = "GOOGLE_API_KEY";
              openrouter.apiKeyEnv = "OPENROUTER_API_KEY";
              cloudflare-workers-ai.apiKeyEnv = "CLOUDFLARE_WORKERS_AI_API_KEY";
              intern-ai = {
                displayName = "Intern InkStone";
                apiKeyEnv = "INTERN_AI_API_KEY";
                api = "anthropic-messages";
                baseURL = "https://discovery-api.intern-ai.org.cn";
              };
              shorin = {
                displayName = "SHORiN API";
                apiKeyEnv = "SHORIN_API_KEY";
                api = "openai-responses";
                baseURL = "https://api.shorin.xyz/v1";
              };
            };
          }
          {
            id = "ui-theme";
            name = "@deepseek-ai/dsh-client-ui-theme";
            config.preference = "system";
          }
          {
            id = "plugin-market";
            name = "@deepseek-ai/dsh-plugin-market";
            config.indexes = [
              "https://awesome-dsh-plugin.com/index.json"
              "https://api.dshfind.com/market/dsh-index.json"
            ];
          }
        ];
      };

      services.web = {
        enable = true;
        profile = "web";
        inherit (cfg) host port;
      };
    };
  };
}
