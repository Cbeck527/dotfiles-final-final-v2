function tn --description "Change tmux window name"
    if test (count $argv) -ne 1
        echo "Usage: tn <name>"
        return 1
    end

    tmux rename-window $argv[1]
end
