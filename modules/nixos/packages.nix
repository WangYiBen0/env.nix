{
  lib,
  config,
  pkgs,
  ...
}:

lib.mkIf config.machine.modules.packages.enable {
  # Grouped by what a tool is *for*, not by where it came from. The first
  # three groups answer "why is my PATH smaller than Arch's": NixOS ships a
  # much thinner base than Arch's `base` + `base-devel`, so both the console
  # tools and the whole build toolchain are named explicitly here.
  #
  # Already on PATH from NixOS itself (corePackages + defaultPackages) and so
  # deliberately NOT repeated below: bash, coreutils, diffutils, findutils,
  # gawk, gnugrep, gnupatch, gnused, gnutar, gzip, bzip2, xz, zstd, cpio,
  # less, which, time, util-linux, procps, netcat, curl, ncurses, acl, attr,
  # libcap, getent, mkpasswd, perl, rsync, strace, man-db, shadow, sudo,
  # nano, dosfstools. `texinfo` (makeinfo/info) arrives with `texliveFull`
  # further down, and `gpg` with `programs.gnupg` below.
  #
  # `neovim` is also absent on purpose: `programs.neovim` below installs its
  # configured wrapper (with vi/vim aliases) into this very list.
  environment.systemPackages = with pkgs; [
    # ── Arch `base` dependency closure ─────────────────────────────────
    # Everything `base` pulls in — transitively included — that NixOS does
    # not ship: the filesystem and encryption tools, `gettext`, and the
    # CLIs Arch only has because pacman itself links against them.
    file # identify what an unknown blob actually is
    gettext # msgfmt, xgettext, envsubst
    psmisc # killall, pstree, fuser
    cryptsetup # LUKS open/close, veritysetup
    e2fsprogs # mkfs.ext4, fsck, tune2fs
    openssl # the openssl CLI, not just the library
    lz4
    brotli
    libarchive # bsdtar, bsdcpio
    sqlite # sqlite3
    libxml2 # xmllint
    nftables # nft; Arch reaches it through iproute2 -> iptables

    # ── Arch `base-devel` ──────────────────────────────────────────────
    # The toolchain `base-devel` pulls in. NixOS makes none of it implicit,
    # so a plain `./configure && make` dies before it starts.
    gnumake # the attribute is gnumake; there is no pkgs.make
    binutils # ld, as, ar, nm, objdump, readelf, strip
    autoconf
    automake
    m4 # autoconf's macro processor
    libtool
    pkgconf # the pkg-config every ./configure looks for
    bison
    flex
    fakeroot # build as a fake root, the way makepkg does
    debugedit
    gdb
    groff # nroff/troff; also what man-db renders pages with

    # ── Arch `core`, but not pulled in by base or base-devel ───────────
    # Arch's installation guide has you add these by hand, which is why a
    # stock install lacks them too.
    logrotate # rotates /var/log
    inetutils # telnet/ftp/tftp; ssh is still the way in
    man-pages # the section 2/3 pages man-db reads
    vim # vi/vim
    tmux
    lsof # which process still holds that file or mount
    tree
    pv
    bc
    whois
    traceroute

    # ── Build systems ──────────────────────────────────────────────────
    # Not in `base-devel`, but the compilers further down are already here,
    # so these are what makes that toolchain usable on a real project.
    cmake
    meson
    ninja
    ccache

    # ── Version control ────────────────────────────────────────────────
    git
    git-lfs
    glab # the GitLab CLI

    # ── Archives and filesystems ───────────────────────────────────────
    zip
    unzipNLS
    rar
    unrar
    _7zz
    ntfsprogs-plus
    exfatprogs
    xfsprogs

    # ── Hardware and disks ─────────────────────────────────────────────
    pciutils # lspci
    usbutils # lsusb
    smartmontools # smartctl, for a disk that is about to die
    hdparm

    # ── Network ───────────────────────────────────────────────────────
    wget
    aria2
    httpie
    curlie
    doggo # dig, but with output you can actually read
    ipcalc
    iperf3
    tcpdump
    gping
    lftp

    # ── Monitoring and system info ─────────────────────────────────────
    fastfetch
    btop
    procs
    dust
    duf

    # ── Text and data ──────────────────────────────────────────────────
    ripgrep
    fd
    eza
    jq
    yq-go
    jc # command output -> JSON
    sad
    chafa
    hyperfine
    tealdeer
    exiftool

    # ── Terminal and session tooling ───────────────────────────────────
    zsh
    zimfw
    fish
    kitty
    starship
    yazi
    zellij
    fzf
    wl-clipboard
    wayland-utils
    xdg-utils
    desktop-file-utils
    brightnessctl
    trashy
    wiremix
    clock-rs

    # ── Desktop applications ───────────────────────────────────────────
    obs-studio

    # ── Compilers and languages ────────────────────────────────────────
    gcc
    clang
    clang-tools
    stylua
    tree-sitter
    cargo
    rustc
    rustfmt
    python3
    texliveFull
    # graalvm-oracle-25's installCheck canary (jshell) segfaults with exit
    # 139 both locally and on GitHub runners on nixpkgs' 25.0.3 build —
    # skip it until upstream fixes the check, to keep builds and the CI
    # closure alive.
    (graalvmPackages.graalvm-oracle.overrideAttrs (_: {
      doInstallCheck = false;
    }))

    # ── Nix tooling ────────────────────────────────────────────────────
    comma
    nh
    home-manager
    nix-index
    nix-inspect
    manix

    # ── Sandboxing ─────────────────────────────────────────────────────
    bubblewrap
  ];

  environment.variables = {
    EDITOR = "nvim";
  };

  programs = {
    mtr.enable = true;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    fish.enable = true;
    zsh = {
      enable = true;
      enableBashCompletion = false;
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    neovim = {
      enable = true;

      viAlias = true;
      vimAlias = true;
    };
  };
}
