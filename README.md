# dotfiles

My personal dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

## Installation of chezmoi

### Linux and macOS

```sh
# Install Chezmoi and apply the latest dotfiles
sh -c "$(curl -fsLS https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.sh)" -- init --apply Xoffio

# Install Chezmoi only
sh -c "$(curl -fsLS https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.sh)"
```

### Windows

```powershell
# Install Chezmoi and apply the latest dotfiles
iex "& {$(irm https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.ps1)} init --apply Xoffio"

# Install Chezmoi only
iex "& {$(irm https://raw.githubusercontent.com/Xoffio/dotfiles/refs/heads/master/install.ps1)}"
```

## Set up a new machine

Clone this repo and apply it in one step:

```bash
chezmoi init --apply https://github.com/Xoffio/dotfiles.git
```

This pulls down every managed dotfile and, on the first run, downloads
anything declared in `.chezmoiexternal.toml` (lazygit, ripgrep, neovim, etc).

## Day-to-day usage

Pull latest changes from repo

```bash
chezmoi update -v
```

**Add a new dotfile** to be managed:

```bash
chezmoi add ~/.some_config
```

**Edit a managed dotfile** (opens the source copy, not the live one):

```bash
chezmoi edit ~/.some_config
```

You can also edit the live file directly and re-sync it into the source
state with `chezmoi re-add`, but `chezmoi edit` is the safer habit since it
edits the source of truth directly.

**Preview changes** before they touch your home directory:

```bash
chezmoi diff
```

**Apply changes**:

```bash
chezmoi apply -v
```

**Pull in fresh downloads** for anything in `.chezmoiexternal.toml` (nvim,
lazygit, ripgrep) — these are cached and skipped on a normal `apply`, so
this has to be run manually when you want updates:

```bash
chezmoi apply -R
```

**Push changes back to the repo**:

```bash
chezmoi cd
git add -A
git commit -m "update dotfiles"
git push
exit
```

Or without leaving your current shell:

```bash
chezmoi git -- add -A
chezmoi git -- commit -m "update dotfiles"
chezmoi git -- push
```
