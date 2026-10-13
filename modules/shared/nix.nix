{ pkgs, ... }:

{
  # Nix settings for every host. nix.package and nix.settings have the same shape
  # in nix-darwin, NixOS, and Home Manager, so all three import this module.
  nix = {
    package = pkgs.lix;
    settings = {
      warn-dirty = false;

      # Auto-accept nixConfig from flakes (e.g. extra-substituters)
      accept-flake-config = true;

      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
