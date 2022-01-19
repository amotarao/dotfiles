if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (nodenv init - | source)
end

. ~/.config/fish/alias.fish

set PATH $PATH $HOME/bin
set PATH $PATH $HOME/.nodebrew/current/bin
set PKG_CONFIG_PATH /usr/X11/lib/pkgconfig/

bass source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
bass source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
