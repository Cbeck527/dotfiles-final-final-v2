{
  pkgs,
  ...
}:
let
  username = "christopher.becker";
  userHome = "/Users/christopher.becker";
  workEmail = "REDACTED";
in
{
  imports = [
    ../../bootstrap/darwin.nix
    ../../modules/darwin/defaults.nix
    ../../modules/darwin/homebrew.nix
    ../../modules/darwin/services.nix
    ../../modules/darwin/packages.nix
    ../../modules/home-manager.nix
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
    identity.email = workEmail;

    home.packages = with pkgs; [
      pkgs.pkgs-master.claude-code
      aws-sso-cli
      terraform_1_5_7
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
