{ pkgs, ... }:

{
  imports = [
    ./pi.nix
    ./omp.nix
  ];

  home.packages = with pkgs; [
    claude-code
    codex
  ];
}
