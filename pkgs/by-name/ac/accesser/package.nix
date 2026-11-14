{
  lib,
  fetchFromGitHub,
  python3,
  nix-update-script,
}:

python3.pkgs.buildPythonApplication (finalAttrs: {
  pname = "accesser";
  version = "0.11.1";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "URenko";
    repo = "Accesser";
    tag = "v${finalAttrs.version}";
    hash = "sha256-9Kc+GHhp9q3OeDRZo22+sANF8rYshUMdkARJ/R6T67E=";
  };

  build-system = [ python3.pkgs.setuptools ];

  # This is the `[doh,doq]` extra from pyproject.toml, which is what upstream's
  # Dockerfile installs. dnspython only imports httpx/aioquic when a rules file
  # actually names a DoH or DoQ nameserver, and the rules.toml shipped with
  # this package does: its first nameserver is `https://77.88.8.8/dns-query`.
  # Without httpx every request would fail at startup instead of resolving.
  dependencies = with python3.pkgs; [
    packaging
    cryptography
    tld
    dnspython
    httpx
    aioquic
  ];

  # There is no test suite upstream, but the install check below still covers
  # the thing that can break here: `accesser/utils/setting.py` reads rules.toml
  # and config.toml from the package directory at import time, so a missing
  # package-data entry fails on the very first invocation, not at build time.
  # `doCheck` stays at its default: mk-python-derivation derives
  # doInstallCheck from it, and setting it to false disables the check below.
  installCheckPhase = ''
    runHook preInstallCheck

    # Importing the package writes rules.toml, config.toml and rules/ into the
    # working directory, so run it where that is allowed. `--help` exits during
    # argument parsing, before any certificate or network work happens.
    tmp=$(mktemp -d)
    ( cd "$tmp" && HOME="$tmp" "$out/bin/accesser" --help > /dev/null )

    runHook postInstallCheck
  '';

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Local HTTPS proxy that circumvents SNI RST for sites such as Wikipedia and Pixiv";
    homepage = "https://github.com/URenko/Accesser";
    license = lib.licenses.gpl3Plus;
    mainProgram = "accesser";
    platforms = lib.platforms.unix;
  };
})
