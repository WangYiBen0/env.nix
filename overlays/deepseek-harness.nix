# Pin deepseek-harness to the dsh-v0.2.1-rc.2 tag. nixpkgs currently ships
# 0.2.1-alpha.3, whose plugin surface is incompatible with our workspace
# plugins; hold the package on the exact release until nixpkgs catches up,
# then drop this file. The nixpkgs derivation is reused wholesale via
# overrideAttrs — only the version, the source tree and the pnpm dependency
# store change. The expose-internals patch nixpkgs carries still applies to
# rc.2 (the resolver.ts context drifted by ~200 lines but patches cleanly)
# and is still required: node-addon-require-builtin's binary scan does not
# recognize toolchain-built Node.
_: _final: prev: {
  deepseek-harness = prev.deepseek-harness.overrideAttrs (
    finalAttrs: prevAttrs: {
      version = "0.2.1-rc.2";

      src = prev.fetchFromGitHub {
        owner = "deepseek-ai";
        repo = "deepseek-harness";
        tag = "dsh-v${finalAttrs.version}";
        hash = "sha256-zHC9ywS/JBZVJW1Kxcjw371spoOaVllw3h30nfcTJUY=";

        # Same trick as the nixpkgs derivation: capture the commit hash at
        # fetch time so the client build can stamp it without a git dependency.
        leaveDotGit = true;
        postFetch = ''
          cd $out
          git rev-parse HEAD > .git-commit
          rm -rf .git
        '';
      };

      # Dependency store built from the rc.2 lockfile; arguments mirror the
      # nixpkgs derivation (pnpm_11, fetcherVersion = 4).
      pnpmDeps = prev.fetchPnpmDeps {
        inherit (prevAttrs) pname;
        inherit (finalAttrs) version src;
        pnpm = prev.pnpm_11;
        fetcherVersion = 4;
        hash = "sha256-C9Aw9AS4r7zubaEuT6mLXQ+AhhMVlTxPZRKTpzRUkcU=";
      };
    }
  );
}
