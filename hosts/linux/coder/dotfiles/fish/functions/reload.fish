function reload --wraps='exec fish' --description 'Reload the fish shell'
    # Use exec to replace the current shell process
    exec fish $argv
end
