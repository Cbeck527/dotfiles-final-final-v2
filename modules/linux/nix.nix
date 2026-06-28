{ pkgs, ... }:

{
  nix = {
    enable = true;
    package = pkgs.lix;
    settings = {
      warn-dirty = false;
      accept-flake-config = true;
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };
}
