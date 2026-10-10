{ pkgs, ... }:

{
  # package config
  nixpkgs.config.allowUnfree = true;

  # Enough to clone this repo and run `just switch` on the host itself
  environment.systemPackages = with pkgs; [
    git
    just
  ];

  nix = {
    # Lix everywhere, matching modules/darwin/defaults.nix and modules/linux/nix.nix
    package = pkgs.lix;
    settings = {
      warn-dirty = false;

      # Appended to the NixOS default of [ "root" ]
      trusted-users = [ "@wheel" ];

      # Auto-accept nixConfig from flakes (e.g. extra-substituters)
      accept-flake-config = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];

      keep-outputs = true;
      keep-derivations = true;
    };

    # The system is built from this flake, not from channels
    channel.enable = false;

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "Sun 02:00";
      options = "--delete-older-than 30d";
    };
  };
}
