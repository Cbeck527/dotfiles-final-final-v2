{ pkgs, ... }:

{
  # Development tooling for hosts I write code on
  imports = [ ../../packages/k9s.nix ];

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
    # Only the binary. On coder, the Hjem-managed dotfiles/fish/conf.d/zoxide.fish
    # runs `zoxide init --cmd j` itself, so programs.zoxide would init it twice.
    zoxide

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
