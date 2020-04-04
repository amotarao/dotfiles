. ~/.config/fish/alias.fish

set PATH $PATH /usr/local/bin
set PATH $PATH /usr/bin
set PATH $PATH $HOME/bin
set PATH $PATH $HOME/work/bin
set PATH $PATH /bin
set PATH $PATH /usr/sbin
set PATH $PATH /sbin
set PATH $PATH $HOME/.nodebrew/current/bin
set PATH $PATH $HOME/google-cloud-sdk/bin

set PKG_CONFIG_PATH /usr/X11/lib/pkgconfig/

bass source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
bass source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
