# per distinguere linea di comando e output
PS1='\[\e[36m\][\[\e[34m\]@\h\[\e[36m\]]-[\[\e[33m\]\D{%H:%M:%S}\[\e[36m\]]-[\[\e[32m\]\w\[\e[36m\]]\[\e[0m\] $ '

export PATH="/Users/paolodeidda/.pixi/bin:$PATH"
. "$HOME/.cargo/env"
export PATH="/opt/homebrew/bin:$PATH"

alias sem='cd ~/Documents/UNI/Master/sem4'
alias doc='cd ~/Documents'
alias dwn='cd ~/Downloads'
alias vm='cd ~/vm-share'

export PATH="/opt/homebrew/bin:$PATH"
alias gcc="gcc-15"
alias g++="g++-15"

# OpenClaw Completion
source "/Users/paolodeidda/.openclaw/completions/openclaw.bash"
