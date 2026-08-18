# Doom emacs CLI
fish_add_path -gP $XDG_CONFIG_HOME/emacs/bin

# NOTE: the macOS Emacs.app path additions from the original config are dropped
# here; this host is Linux only. GPG_TTY is also dropped because Home Manager
# sets it in config.fish (modules/programs/gpg.nix).
