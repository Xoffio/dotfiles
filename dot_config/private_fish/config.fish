fish_add_path ~/.local/bin

set -U fish_greeting ""

if status is-interactive
    # Commands to run in interactive sessions can go here
end

if status is-interactive
    atuin init fish | source
end
