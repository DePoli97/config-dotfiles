export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export PATH="/Library/TeX/texbin:$PATH"

# Carica anche ~/.bashrc se esiste
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi

eval "$(/opt/homebrew/bin/brew shellenv)"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/paolodeidda/miniforge3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/paolodeidda/miniforge3/etc/profile.d/conda.sh" ]; then
        . "/Users/paolodeidda/miniforge3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/paolodeidda/miniforge3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

. "$HOME/.cargo/env"

# Prefer Homebrew GCC 15 instead of Apple Clang
export PATH="/opt/homebrew/bin:$PATH"
export GCC=gcc-15
export GXX=g++-15
export CPP=g++-15
export CXX=g++-15
# Added by Antigravity
export PATH="/Users/paolodeidda/.antigravity/antigravity/bin:$PATH"

# Added by Antigravity
export PATH="/Users/paolodeidda/.antigravity/antigravity/bin:$PATH"
