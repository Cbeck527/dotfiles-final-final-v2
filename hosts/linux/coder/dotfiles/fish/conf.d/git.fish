set -gx GIT_MERGE_AUTOEDIT 0

# Git abbreviations (more efficient than functions for simple aliases)
if status is-interactive
    abbr -a ga git add
    abbr -a gc git commit
    abbr -a gd git diff
    abbr -a gs git status
end
