# filename includes `03` prefix to allow atuin to override C-R keybinding

# disable ALT-C
set -gx FZF_ALT_C_COMMAND
set -gx FZF_DEFAULT_OPTS --no-height --color fg:-1,bg:-1,hl:136,fg+:254,bg+:-1,hl+:136 --color info:136,prompt:136,pointer:230,marker:230,spinner:136

# NOTE: `fzf --fish | source` is intentionally omitted here. Home Manager does
# it in config.fish via programs.fzf.enableFishIntegration, and sourcing it
# twice binds the fzf keys twice.
