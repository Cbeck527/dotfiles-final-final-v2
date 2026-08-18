# Zoxide - smarter cd command
if status is-interactive; and command -v zoxide >/dev/null
    zoxide init --cmd j fish | source

    # Additional aliases for convenience
    abbr -a zq 'zoxide query' # Query the database
    abbr -a za 'zoxide add' # Manually add a directory
end
