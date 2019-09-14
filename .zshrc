export PATH=$PATH:$HOME/bin
export PATH=$PATH:$HOME/work/bin
export PATH=$PATH:/usr/local/bin
export PATH=$PATH:/usr/bin
export PATH=$PATH:/bin
export PATH=$PATH:/usr/sbin
export PATH=$PATH:/sbin

export PATH=$PATH:$HOME/.nodebrew/current/bin
export PATH=$PATH:$HOME/google-cloud-sdk/bin
export PATH=$PATH:$HOME/development/flutter/bin

export GOPATH=$HOME/work
export ZSH=$HOME/.oh-my-zsh

export PKG_CONFIG_PATH=/usr/X11/lib/pkgconfig/

if [ -f "${HOME}/google-cloud-sdk/path.zsh.inc" ]; then source "${HOME}/google-cloud-sdk/path.zsh.inc"; fi
if [ -f "${HOME}/google-cloud-sdk/completion.zsh.inc" ]; then source "${HOME}/google-cloud-sdk/completion.zsh.inc"; fi

ZSH_THEME="robbyrussell"
plugins=(git ruby osx bundler brew rails emoji-clock)

source $ZSH/oh-my-zsh.sh
source $HOME/.zsh/alias.sh
