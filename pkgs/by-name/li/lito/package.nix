{
  lib,
  fetchFromGitHub,
  fetchzip,
  llvmPackages_22,
  cmake,
  ninja,
  pkg-config,
  glibc,
  zstd,
  openssl,
  nix-update-script,
}:

# Lito mirrors its own flake.nix: a libcxxStdenv cmake build whose vendored
# third-party sources are injected through FETCHCONTENT_SOURCE_DIR_* and kept
# offline with FETCHCONTENT_FULLY_DISCONNECTED. LLVM 22 is required: rstd uses
# the `__builtin_ctzg` vector form that clang 21 rejects.
let
  version = "0.8.6";

  # Copy of lito's own deps.json (pinned by the upstream flake), inlined to
  # avoid importing a derivation's file during evaluation.
  deps = {
    rstd = {
      owner = "litocpp";
      repo = "rstd";
      rev = "0c755371a02ccee658fa6d63728b6078cb2f9070";
      hash = "sha256-JqwAOvqQYzh1v9FlA4Spuab7I6gOu/f3uiVFXiwZS0E=";
    };
    luato = {
      owner = "litocpp";
      repo = "luato";
      rev = "df0c6f2d1cce2051b4711d36067619eda7933683";
      hash = "sha256-XL1evcZbZJ2LfTi5T9UQ+4YBEw5YnDsGeY3IBS+Fs5U=";
    };
    licrypto = {
      owner = "litocpp";
      repo = "licrypto";
      rev = "40da005cbd7faf1328fd29a01cb0c534d6998612";
      hash = "sha256-Aussj13CS3lAIR0TmmU7NgVQg2l2QUdiNS47oa7Fcaw=";
    };
    zstd = {
      owner = "facebook";
      repo = "zstd";
      rev = "f8745da6ff1ad1e7bab384bd1f9d742439278e99";
      hash = "sha256-tNFWIT9ydfozB8dWcmTMuZLCQmQudTFJIkSr0aG7S44=";
    };
  };

  fetchDependency =
    name:
    fetchFromGitHub {
      inherit (deps.${name})
        owner
        repo
        rev
        hash
        ;
    };

  luaSrc = fetchzip {
    url = "https://www.lua.org/ftp/lua-5.5.1.tar.gz";
    hash = "sha256-vb3Nt5dMPL/G6L1MmJPGQnQT3F8p6iK6Gu2F/cG00ho=";
  };
in
llvmPackages_22.libcxxStdenv.mkDerivation {
  pname = "lito";
  inherit version;

  src = fetchFromGitHub {
    owner = "litocpp";
    repo = "lito";
    # tag v0.8.6; pinned by commit so the fetcher downloads the tarball
    # directly instead of resolving the tag through the rate-limited
    # GitHub commits API.
    rev = "f9d295560796ee2503dec6948a1b08edf82cda0d";
    hash = "sha256-5KOC3DQe5N3/KrHNObzF4q3kG/4yxu674NCbEDzD28A=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    llvmPackages_22.lld
  ];

  buildInputs = [
    zstd
    openssl
  ];

  cmakeFlags = [
    "-DCMAKE_C_COMPILER=clang"
    "-DCMAKE_CXX_COMPILER=clang++"
    "-DCMAKE_AR=${llvmPackages_22.llvm}/bin/llvm-ar"
    "-DCMAKE_RANLIB=${llvmPackages_22.llvm}/bin/llvm-ranlib"
    "-DCMAKE_CXX_COMPILER_AR=${llvmPackages_22.llvm}/bin/llvm-ar"
    "-DCMAKE_C_COMPILER_AR=${llvmPackages_22.llvm}/bin/llvm-ar"
    "-DCMAKE_CXX_COMPILER_RANLIB=${llvmPackages_22.llvm}/bin/llvm-ranlib"
    "-DCMAKE_C_COMPILER_RANLIB=${llvmPackages_22.llvm}/bin/llvm-ranlib"
    "-DCMAKE_CXX_STANDARD_INCLUDE_DIRECTORIES=${llvmPackages_22.libcxx.dev}/include/c++/v1;${llvmPackages_22.libcxx.dev}/include;${glibc.dev}/include"
    "-DFETCHCONTENT_SOURCE_DIR_RSTD=${fetchDependency "rstd"}"
    "-DFETCHCONTENT_SOURCE_DIR_LUATO=${fetchDependency "luato"}"
    "-DFETCHCONTENT_SOURCE_DIR_LICRYPTO=${fetchDependency "licrypto"}"
    "-DFETCHCONTENT_SOURCE_DIR_ZSTD=${fetchDependency "zstd"}"
    "-DFETCHCONTENT_SOURCE_DIR_LUA=${luaSrc}"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
  ];

  # _FORTIFY_SOURCE triggers a hard error under libc++ without optimization
  # in some translation units; lito disables it upstream.
  NIX_CFLAGS_COMPILE = "-U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=0";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Module-first C++ builder";
    homepage = "https://github.com/litocpp/lito";
    changelog = "https://github.com/litocpp/lito/releases";
    license = with lib.licenses; [
      mit
      asl20
    ];
    mainProgram = "lito";
    platforms = lib.platforms.unix;
  };
}
