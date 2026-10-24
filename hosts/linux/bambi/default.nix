{
  # pkgs,
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

  machine.username = "chris";
  machine.home = "/home/chris";

  home = {
    username = config.machine.username;
    homeDirectory = config.machine.home;
    stateVersion = "25.05";

    # packages = with pkgs; [
    # ];
  };

  # only true on darwin by default
  custom.git.githubCredentialHelper.enable = true;

  # Home Manager can't change the /etc/passwd login shell, and a nix-profile
  # fish there breaks logins if the profile is ever missing. Keep bash as the
  # login shell and exec fish for interactive sessions instead.
  custom.bash.fishHandoff.enable = true;
}
