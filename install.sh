#!/bin/bash

# install Homebrew
if test ! $(which brew); then
	echo "Installing Homebrew."
	/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
	echo "Homebrew is already installed."
fi

brew update
brew upgrade

# install brew-cask
brew tap caskroom/cask
brew install caskroom/cask/brew-cask
./installs/brew-cask.sh

# insatll wget
brew install wget
