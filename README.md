# dotfiles

My personal configuration files for nvim, tmux, ghostty, zsh, and VS Code. Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

```bash
config-dotfiles/
├── nvim/.config/nvim/
├── tmux/.tmux.conf
├── ghostty/.config/ghostty/config
├── zsh/.zshrc
└── vscode/Library/Application Support/Code/User/settings.json
```

## Requirements

```bash
brew install stow
```

## Installation

```bash
cd ~
git clone https://github.com/paolodeidda/config-dotfiles.git
cd ~/config-dotfiles
stow -t ~ nvim tmux ghostty zsh vscode
```

This creates symlinks from the expected config locations to the files in this repo.

## How Stow maps paths

- Stow mirrors each package path into the target.
- Example: `vscode/Library/Application Support/Code/User/settings.json` becomes `~/Library/Application Support/Code/User/settings.json`.
- The created item in home is a symlink that points back to this repository from one level higher in the directory structure.
