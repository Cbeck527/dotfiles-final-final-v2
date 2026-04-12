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

  nix.settings.trusted-users = lib.mkAfter [ username ];

  system.primaryUser = username;

  custom.homebrew.excludeCasks = [ "contexts" ];

  home-manager.users.${username} = {
    programs.k9s.views = {
      "v1/pods" = {
        sortColumn = "NAME:asc";
        columns = [
          "NAMESPACE"
          "NAME"
          "APP:.metadata.labels.app"
          "STATUS"
          "TYPE:.metadata.labels.rodeo-component-type|W"
          "OWNER:.metadata.labels.owner|W"
          "IP"
          "NODE"
          "READY"
          "READINESS GATES"
          "AGE"
          "RESTARTS"
          "CPU/R:L"
          "MEM/R:L"
          "LABELS|H"
          "NOMINATED NODE|H"
          "QOS|H"
        ];
      };
      "apps/v1/deployments" = {
        columns = [
          "NAME"
          "APP:.metadata.labels.app"
          "TYPE:.metadata.labels.rodeo-component-type"
          "COMPONENT:.metadata.labels.component|W"
          "READY"
          "UP-TO-DATE"
          "AVAILABLE"
          "AGE"
          "LABELS|H"
        ];
      };
      "v1/services" = {
        columns = [
          "NAME"
          "TYPE:.metadata.labels.component"
          "TYPE"
          "SELECTOR|W"
          "CLUSTER-IP"
          "EXTERNAL-IP|W"
          "PORTS"
          "AGE"
          "LABELS|H"
        ];
      };
      "v1/nodes" = {
        sortColumn = "AGE:asc";
        columns = [
          "INSTANCE ID:.metadata.labels.instance-id"
          "IP:.metadata.annotations.alpha\\.kubernetes\\.io/provided-node-ip"
          "CAPACITY TYPE:.metadata.labels.eks\\.amazonaws\\.com/capacityType"
          "NODE GROUP:.metadata.labels.eks\\.amazonaws\\.com/nodegroup"
          "AZ:.metadata.labels.topology\\.kubernetes\\.io/zone"
          "TAINTS"
          "STATUS"
          "PODS"
          "AGE"
          "VERSION|W"
          "INTERNAL-IP|H"
          "EXTERNAL-IP|H"
          "NAME|H"
          "ROLE|H"
        ];
      };
    };

    home.packages = with pkgs; [
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
