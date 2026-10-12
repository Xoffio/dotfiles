fish_add_path ~/.local/bin

set -U fish_greeting ""

# Enable vi key bindings
fish_vi_key_bindings

if status is-interactive
    # Load the atuin shell integration if atuin is installed
    if command -q atuin
        atuin init fish | source
    end

    # Load fzf key bindings and fuzzy completion
    if command -q fzf
        fzf --fish | source

        # Preview files with bat + file type header (Ctrl-T)
        set -gx FZF_CTRL_T_OPTS "--preview 'bat -n --color=always {}' --bind 'focus:+transform-header:file --brief {} || echo \"No file selected\"'"

        # Use full preset style with colors (Shift-Tab)
        set -gx FZF_DEFAULT_OPTS "--style full --border --padding 1,2 --color 'border:#aaaaaa,label:#cccccc' --color 'preview-border:#9999cc,preview-label:#ccccff' --color 'list-border:#669966,list-label:#99cc99' --color 'input-border:#996666,input-label:#ffcccc' --color 'header-border:#6699cc,header-label:#99ccff'"
    end
end

alias wm workmux
