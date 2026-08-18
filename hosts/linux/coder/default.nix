{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/shared/identity.nix
    ../../../modules/linux/nix.nix
    ../../../modules/programs/bash.nix
    ../../../modules/programs/fish.nix
    ../../../modules/programs/gpg.nix
    ../../../modules/programs/git.nix
    ../../../modules/programs/my-prompt.nix
    ../../../modules/programs/tmux.nix
  ];

  machine.username = "christopher-becker";
  machine.home = "/home/christopher-becker";

  home = {
    username = config.machine.username;
    homeDirectory = config.machine.home;
    stateVersion = "25.05";

    packages = with pkgs; [
      aspell
      # `clang-format` has no top-level attribute; the binary ships in clang-tools.
      clang-tools
      dasel
      # custom.git.extras.enable is false here, so programs.delta (and its git
      # integration) is off — this is the bare binary.
      delta
      dprint
      fd
      gh
      go-grip
      just
      # Required by the Hjem-managed dotfiles/fish/conf.d/zoxide.fish, which
      # runs `zoxide init --cmd j` itself. programs.zoxide is deliberately not
      # used, to avoid a second init in config.fish.
      zoxide

      # Rust, from the fenix overlay (see flake.nix) to match the Darwin hosts
      (pkgs.fenix.stable.withComponents [
        "cargo"
        "rust-analyzer"
        "rustc"
        "rustfmt"
      ])

      # Dotfile management; see hjem.nix in this directory
      inputs.hjem.packages.${pkgs.stdenv.hostPlatform.system}.hjem
      inputs.zmx.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  programs.home-manager.enable = true;

  # The Coder agent runs its plumbing through the login shell from /etc/passwd,
  # and parts of it are bash-only. Keep bash there and exec fish for interactive
  # sessions; `just login-shell-bash` sets the passwd entry to match.
  custom.bash.fishHandoff.enable = true;

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    config.global.load_dotenv = true;
  };

  programs.ripgrep = {
    enable = true;
    arguments = [
      "--no-heading"
      "--no-line-number"
      "--context=0"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "Solarized (dark)";
      style = "plain";
    };
  };

  programs.eza = {
    enable = true;
    # The Hjem-managed dotfiles/fish/conf.d/eza.fish defines the full set of
    # list functions (l, lg, lm, lt, ltl, lz, ...). Home Manager's integration
    # writes ls/ll/la/lt aliases into config.fish, which is sourced after
    # conf.d and would shadow them.
    enableFishIntegration = false;
    theme.punctuation.foreground = "Default";
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
