fish_add_path ~/.local/bin

set -U fish_greeting ""

if status is-interactive

    # Load the atuin shell integration if atuin is installed
    if command -q atuin
        atuin init fish | source
    end
end

alias wm workmux
