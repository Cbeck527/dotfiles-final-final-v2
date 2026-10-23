{ pkgs, config, ... }:

let
  inherit (config.xdg) cacheHome dataHome;
in
{
  # Development tooling for hosts I write code on
  imports = [ ../../packages/k9s.nix ];

  programs.zoxide = {
    enable = true;
    options = [
      "--cmd"
      "j"
    ];
  };

  programs.fish = {
    shellAbbrs = {
      zq = "zoxide query";
      za = "zoxide add";
    };
    functions.k = {
      wraps = "kubectl";
      body = "kubectl $argv";
    };
  };

  # Keep language toolchains out of $HOME
  home.sessionVariables = {
    # Python
    PYTHONDONTWRITEBYTECODE = "1";
    VIRTUAL_ENV_DISABLE_PROMPT = "1";
    GTAGSLABEL = "pygments";
    PYTHONUSERBASE = "${dataHome}/python";
    PYTHONPYCACHEPREFIX = "${cacheHome}/python";
    PIP_CACHE_DIR = "${cacheHome}/pip";
    UV_CACHE_DIR = "${cacheHome}/uv";

    # Rust
    CARGO_HOME = "${dataHome}/cargo";
    RUSTUP_HOME = "${dataHome}/rustup";

    # Go
    GOPATH = "${dataHome}/go";
    GOMODCACHE = "${cacheHome}/go/mod";
    GOCACHE = "${cacheHome}/go/build";

    # Don't show fish-lsp pop-ups in emacs
    fish_lsp_show_client_popups = "false";
  };

  home.sessionPath = [
    "${dataHome}/python/bin"
    "${dataHome}/cargo/bin"
    "${dataHome}/go/bin"
  ];

  home.packages = with pkgs; [
    aspell
    # `clang-format` has no top-level attribute; the binary ships in clang-tools.
    clang-tools
    dasel
    dprint
    fd
    gh
    go-grip
    just

    # Development Tools
    automake
    cmake
    go
    lua-language-server
    nodejs
    pnpm
    statix
    stylua
    shellcheck

    # Cloud & Infrastructure
    awscli
    docker
    docker-buildx
    kubectl
    kubernetes-helm

    # Languages / LSP
    awk-language-server
    basedpyright
    bash-language-server
    buf # protobufs
    dockerfile-language-server
    fish-lsp
    golangci-lint
    gopls
    nil # nix lsp
    (python3.withPackages (ps: [ ps.pip ]))

    # Better Rust w/ nix-community fenix
    cargo-deny
    cargo-expand
    cargo-fuzz
    (pkgs.fenix.stable.withComponents [
      "cargo"
      "clippy"
      "rust-analyzer"
      "rust-src"
      "rustc"
      "rustfmt"
    ])

    terraform-ls
    typescript
    typescript-language-server
    vscode-langservers-extracted
    yaml-language-server
  ];
}
