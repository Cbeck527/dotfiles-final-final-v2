{ pkgs, ... }:

{
  home.packages = with pkgs; [ omp ];
}
