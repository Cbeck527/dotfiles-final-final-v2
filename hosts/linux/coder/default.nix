{
  pkgs,
  config,
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
    ];
  };

  custom.git.githubCredentialHelper.enable = false;
  custom.git.extras.enable = false;

  # The Coder agent runs its plumbing through the login shell from /etc/passwd,
  # and parts of it are bash-only. Keep bash there and exec fish for interactive
  # sessions; `just login-shell-bash` sets the passwd entry to match.
  custom.bash.fishHandoff.enable = true;
}
