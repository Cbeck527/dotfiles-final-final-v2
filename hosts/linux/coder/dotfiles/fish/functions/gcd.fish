function gcd --description 'cd to the root of a git repository'
    cd (git rev-parse --show-toplevel)
end
