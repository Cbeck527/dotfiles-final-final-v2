{
  pkgs,
  config,
  inputs,
  ...
}:
{
  imports = [
    ../../../modules/shared/machine.nix
    ../../../modules/shared/nix.nix
    ../../../modules/home/base.nix
    ../../../modules/home/dev.nix
    ../../../packages/bash.nix
  ];

  machine.username = "christopher-becker";
  machine.home = "/home/christopher-becker";

  home = {
    username = config.machine.username;
    homeDirectory = config.machine.home;
    stateVersion = "25.05";

    packages = with pkgs; [
      # custom.git.extras.enable is false here, so programs.delta (and its git
      # integration) is off — this is the bare binary.
      delta
      herdr

      # Dotfile management; see hjem.nix in this directory
      inputs.hjem.packages.${pkgs.stdenv.hostPlatform.system}.hjem
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  # The Coder agent runs its plumbing through the login shell from /etc/passwd,
  # and parts of it are bash-only. Keep bash there and exec fish for interactive
  # sessions; `just login-shell-bash` sets the passwd entry to match.
  custom.bash.fishHandoff.enable = true;

  programs.eza = {
    # The Hjem-managed dotfiles/fish/conf.d/eza.fish defines the full set of
    # list functions (l, lg, lm, lt, ltl, lz, ...). Home Manager's integration
    # writes ls/ll/la/lt aliases into config.fish, which is sourced after
    # conf.d and would shadow them.
    enableFishIntegration = false;
  };
}
