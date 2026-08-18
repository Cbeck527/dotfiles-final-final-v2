function colors
    set -l colors red green yellow blue magenta cyan white black
    for color in $colors
        printf "%b%s\t\t%b%s\t\t%b%s\t\t%b%s\n" \
            (set_color $color) $color \
            (set_color br$color) "bright_$color" \
            (set_color -o $color) bold_$color \
            (set_color -o br$color) "bold_bright_$color"
    end
end
