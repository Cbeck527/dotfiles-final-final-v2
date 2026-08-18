# Solarized dark syntax highlighting colors.
#
# These were universal variables (SETUVAR) in the old dotfiles' fish_variables.
# That file is fish's own mutable state — fish rewrites it whenever a universal
# variable changes — so it can't be a read-only symlink into the Nix store.
# Setting them as globals here is equivalent: when fish resolves a variable it
# checks global scope before universal scope.
#
# Pager colors are deliberately not repeated here; 01-colors.fish already sets
# those, and it likewise shadowed the universal values in the old setup.

set -g fish_color_autosuggestion 586e75
set -g fish_color_cancel --reverse
set -g fish_color_command 93a1a1
set -g fish_color_comment 586e75
set -g fish_color_cwd green
set -g fish_color_cwd_root red
set -g fish_color_end 268bd2
set -g fish_color_error dc322f
set -g fish_color_escape 00a6b2
set -g fish_color_history_current --bold
set -g fish_color_host normal
set -g fish_color_match --background=brblue
set -g fish_color_normal normal
set -g fish_color_operator 00a6b2
set -g fish_color_param 839496
set -g fish_color_quote 657b83
set -g fish_color_redirection 6c71c4
set -g fish_color_search_match red
set -g fish_color_selection white --bold --background=brblack
set -g fish_color_status red
set -g fish_color_user brgreen
set -g fish_color_valid_path --underline
