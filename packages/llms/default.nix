{ pkgs, ... }:

{
  imports = [
    ./pi.nix
    ./omp.nix
  ];

  home.packages = with pkgs; [
    amp
    claude-code
    codex
  ];
}
