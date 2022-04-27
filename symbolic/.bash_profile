export PATH="$HOME/.rbenv/shims:$PATH"
export PATH="$HOME/flutter/bin:$PATH"

eval "$(nodenv init -)"
eval "$(rbenv init -)"

# The next line updates PATH for the Google Cloud SDK.
if [ -f "$HOME/google-cloud-sdk/path.bash.inc" ]; then . "$HOME/google-cloud-sdk/path.bash.inc"; fi

# The next line enables shell command completion for gcloud.
if [ -f "$HOME/google-cloud-sdk/completion.bash.inc" ]; then . "$HOME/google-cloud-sdk/completion.bash.inc"; fi

if [ -f ~/.bashrc ] ; then
  . ~/.bashrc
fi
