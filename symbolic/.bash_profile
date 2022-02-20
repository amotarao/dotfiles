export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="$HOME/flutter/bin:$PATH"

eval "$(nodenv init -)"
eval "$(rbenv init -)"

if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi
