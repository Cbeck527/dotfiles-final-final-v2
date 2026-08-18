function incognito --description "Start a new fish shell in incognito mode (no history)"
    # Start a new fish shell with private mode (-P flag)
    # The INCOGNITO_MODE env var is for the starship prompt indicator
    env INCOGNITO_MODE=on fish -P
end
