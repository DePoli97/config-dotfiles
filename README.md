# Dotfiles (stow-ready)

Questa cartella contiene una copia del setup attuale, organizzata per GNU Stow.

Pacchetti inclusi:
- nvim -> ~/.config/nvim
- ghostty -> ~/.config/ghostty
- tmux -> ~/.tmux.conf
- zsh -> ~/.zshrc
- vscode -> ~/Library/Application Support/Code/User/settings.json

## A cosa serve stow
Stow crea symlink dai file nella cartella dotfiles verso la tua home.
In pratica mantieni tutto versionato in un solo posto e lo applichi con un comando.

## Installazione
brew install stow

## Applicare tutto
cd ~/config-dotfiles
stow nvim ghostty tmux zsh vscode -t ~

## Applicare solo un pacchetto
stow nvim -t ~
stow tmux -t ~

## Rimuovere i symlink di un pacchetto
stow -D nvim -t ~

## Nota sui conflitti
Se i file target esistono gia come file reali (non symlink), stow segnala conflitto.
In quel caso sposta/backuppa i file esistenti e rilancia il comando.
