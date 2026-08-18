# solarized dark
set -l solarized_base03 002b36
set -l solarized_base02 073642
set -l solarized_base01 586e75
set -l solarized_base00 657b83
set -l solarized_base0 839496
set -l solarized_base1 93a1a1
set -l solarized_base2 eee8d5
set -l solarized_base3 fdf6e3
set -l solarized_yellow b58900
set -l solarized_orange cb4b16
set -l solarized_red dc322f
set -l solarized_magenta d33682
set -l solarized_violet 6c71c4
set -l solarized_blue 268bd2
set -l solarized_cyan 2aa198
set -l solarized_green 859900

# Set up colors
set -l black $solarized_base02
set -l red $solarized_red
set -l green $solarized_green
set -l yellow $solarized_yellow
set -l blue $solarized_blue
set -l magenta $solarized_magenta
set -l cyan $solarized_cyan
set -l white $solarized_base3
set -l brblack $solarized_base03
set -l brred $solarized_orange
set -l brgreen $solarized_base01
set -l bryellow $solarized_base00
set -l brblue $solarized_base0
set -l brmagenta $solarized_violet
set -l brcyan $solarized_base1
set -l brwhite $solarized_base3

set -g fish_pager_color_progress $white
set -g fish_pager_color_prefix $brgreen
set -g fish_pager_color_completion $white
set -g fish_pager_color_description $yellow
set -g fish_pager_color_selected_background --background=$brcyan
set -g fish_pager_color_selected_prefix $black
set -g fish_pager_color_selected_completion $brcyan
set -g fish_pager_color_selected_description $black
set -g fish_pager_color_secondary_prefix $brcyan
set -g fish_pager_color_secondary_completion
set -g fish_pager_color_secondary_description
