# add a !! like bash
function last_history_item
    echo $history[1]
end
abbr -a !! --position anywhere --function last_history_item

# `unset` like bash
abbr -a unset --position command set -e

function _custom_complete_j
    if commandline --paging-mode
        commandline -f down-line
    else
        commandline -f execute
    end
end

function _custom_complete_k
    if commandline --paging-mode
        commandline -f up-line
    else
        commandline -f kill-line
    end
end

function _custom_complete_h
    if commandline --paging-mode
        commandline -f backward-char
    else
        commandline -f backward-char
    end
end

function _custom_complete_l
    if commandline --paging-mode
        commandline -f forward-char
    else
        commandline -f clear-screen
    end
end

function _custom_complete_tab
    if commandline --paging-mode
        commandline -f accept-autosuggestion
    else
        commandline -f complete
    end
end

function fish_user_key_bindings
    # vim-like autocomplete navigation
    bind \ch _custom_complete_h
    bind \cj _custom_complete_j
    bind \ck _custom_complete_k
    bind \cl _custom_complete_l

    # C-x C-e like in bash
    bind \cX\cE edit_command_buffer
end
