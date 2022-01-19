if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi

export PATH="$HOME/.rbenv/bin:$PATH"

eval "$(nodenv init -)"
eval "$(rbenv init -)"
