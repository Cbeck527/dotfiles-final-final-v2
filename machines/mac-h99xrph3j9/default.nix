{
  pkgs,
  ...
}:
let
  username = "christopher.becker";
  userHome = "/Users/christopher.becker";
in
{
  imports = [
    ../../bootstrap/darwin.nix
    ../../modules/darwin/defaults.nix
    ../../modules/emacs-macport.nix
  ];

  system.primaryUser = username;

  _module.args = { inherit username userHome; };

  nix-homebrew = {
    enable = true;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    mutableTaps = true;
  };

  custom.homebrew.excludeCasks = [ "contexts" ];

  home-manager.users.${username} = {
    programs.git.settings.user.email = "REDACTED";
    home.packages = with pkgs; [
      pkgs.pkgs-master.claude-code
      aws-sso-cli
      terragrunt

      nodePackages_latest.prettier
    ];
  };

  system.defaults.universalaccess = { };

  homebrew.taps = [ ];

  homebrew.brews = [ ];

  homebrew.casks = [
    "yaak"
  ];

  # TODO: handle mac app store apps?
  # utc-time - https://sindresorhus.com/utc-time
  # dato - https://sindresorhus.com/dato
}
