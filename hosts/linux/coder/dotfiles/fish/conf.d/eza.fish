set -gx EZA_CONFIG_DIR $XDG_CONFIG_HOME/eza

# Define eza functions only in interactive mode and if eza is available
if status is-interactive; and command -v eza >/dev/null
    function ls --wraps=eza --description 'List files with eza'
        eza -lF --group-directories-first $argv
    end

    function lsa --wraps=eza --description 'List all files including hidden'
        eza -lF --all --all --group-directories-first $argv
    end

    function ll --wraps=eza --description 'List files with permissions'
        eza -lF --group-directories-first --octal-permissions $argv
    end

    function l --wraps=eza --description 'List files in simple format'
        eza -1F --group-directories-first $argv
    end

    function lt --wraps=eza --description 'List files in tree format (2 levels)'
        eza -lF --tree --level=2 --group-directories-first $argv
    end

    function ltl --wraps=eza --description 'List files in full tree format'
        eza -lF --tree --group-directories-first $argv
    end

    function lg --wraps=eza --description 'List files with git status'
        eza -lF --git --git-repos --group-directories-first $argv
    end

    function lm --wraps=eza --description 'List files sorted by modification time'
        eza -lF --sort=modified --group-directories-first $argv
    end

    function lz --wraps=eza --description 'List files sorted by size'
        eza -lF --sort=size --group-directories-first $argv
    end
end
