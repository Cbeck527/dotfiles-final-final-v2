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
}
