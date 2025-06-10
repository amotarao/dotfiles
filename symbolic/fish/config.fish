# volta
set -gx VOLTA_HOME $HOME/.volta
fish_add_path $VOLTA_HOME/bin

# bun 
set -gx BUN_INSTALL $HOME/.bun
fish_add_path $BUN_INSTALL/bin
