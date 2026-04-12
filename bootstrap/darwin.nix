{
  lib,
  pkgs,
  ...
}:

{
  # Nix configuration ------------------------------------------------------------------------------

  nix.settings = {
    substituters = [
      "https://cache.nixos.org/"
      "https://nix-community.cachix.org"
    ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];

    trusted-users = [ "@admin" ];

    # Auto-accept nixConfig from flakes (e.g. extra-substituters)
    accept-flake-config = true;

    experimental-features = [
      "nix-command"
      "flakes"
    ];

    keep-outputs = true;
    keep-derivations = true;

    extra-platforms = lib.mkIf (pkgs.stdenv.hostPlatform.system == "aarch64-darwin") [
      "aarch64-darwin"
    ];
  };

  nix.optimise.automatic = true;

  # Shells -----------------------------------------------------------------------------------------

  # Add shells installed by nix to /etc/shells file
  environment.shells = with pkgs; [
    bashInteractive
    fish
    zsh
  ];

  # Enable zsh for compatibility, but use fish as default shell
  programs.zsh.enable = true;
  environment.variables.SHELL = "${pkgs.fish}/bin/fish";

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;
}
