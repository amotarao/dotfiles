export PATH="$HOME/.rbenv/shims:$PATH"

eval "$(nodenv init -)"
eval "$(rbenv init -)"

if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi
