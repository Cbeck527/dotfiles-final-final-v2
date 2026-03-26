{
  pkgs,
  lib,
  username,
  ...
}:
let
  datadog-pup = pkgs.stdenv.mkDerivation (finalAttrs: {
    pname = "datadog-pup";
    version = "0.27.0";

    src = pkgs.fetchurl {
      url = "https://github.com/DataDog/pup/releases/download/v${finalAttrs.version}/pup_${finalAttrs.version}_Darwin_arm64.tar.gz";
      hash = "sha256-beHU+qv/wv9Fa3oBHlGKjipoIF2Wcnq8CFz1xlyeVwk=";
    };

    sourceRoot = ".";

    installPhase = ''
      install -Dm755 pup $out/bin/pup
    '';
  });
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

  custom.homebrew.excludeCasks = [ "contexts" ];

  home-manager.users.${username} = {
    home.packages = with pkgs; [
      # llms
      claude-code
      codex
      pi

      datadog-pup

      # AWS SSO Integration
      aws-sso-cli

      # terraform version overlay and TF tooling
      terraform_1_5_7
      terragrunt
      nodePackages_latest.prettier
    ];
  };

  homebrew = {
    caskArgs.appdir = "~/Applications";
    casks = [
      "yaak"
    ];
  };

  # TODO: handle mac app store apps?
  # 1PW for Safari - 1569813296
  # utc time - 1538245904
  # dato - 1470584107
  # wipr - 1662217862
  # reader safari extension - 1640236961

  services.caffeinate.enable = true;
}
