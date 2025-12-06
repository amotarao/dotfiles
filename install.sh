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

# oh-my-zsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Gemini CLI
npm install -g @google/gemini-cli

./commands/set-symbolic.sh
