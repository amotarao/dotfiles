#!/bin/bash

# install Homebrew
if test ! $(which brew); then
  echo "Installing Homebrew."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
  echo "Homebrew is already installed."
fi

brew update
brew upgrade

./installs/brew-install.sh
./installs/volta.sh
./installs/bun.sh

./commands/set-symbolic.sh
