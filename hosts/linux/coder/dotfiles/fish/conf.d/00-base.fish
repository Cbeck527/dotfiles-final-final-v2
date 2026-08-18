# set XDG Base Directory Specification
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share

set -gx EDITOR vim
set -gx PAGER less -q

# Prefer US English and use UTF-8.
set -gx LANG en_US.UTF-8
set -gx LC_ALL en_US.UTF-8

# NOTE: take a look at this w/ nix ... might not be needed?
# set -gx PATH /usr/local/bin /usr/bin /bin /usr/sbin /sbin
# set -gx MANPATH /usr/share/man /usr/local/share/man
# set -gx MANPAGER less -X

# homebrew
if test -d /opt/homebrew
    eval (/opt/homebrew/bin/brew shellenv fish)
end

# Add `~/.local/bin` and `~/.bin`
fish_add_path -gP $HOME/.local/bin
fish_add_path -gP $HOME/.bin

# OS-specific customizations
switch (uname)
    case Darwin
        # NOTE: can probably port these to nix/home-manager fish config
        set -gx BROWSER open
        abbr -a dnscache -- dscacheutil -flushcache
        abbr -a e -- emacs -nw
        abbr -a o. open .
end

# Local Variables:
# mode: fish
# End:
