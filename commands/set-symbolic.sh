#!/bin/bash

ln -sf $PWD/symbolic/.profile ~/.profile

ln -sf $PWD/symbolic/.bash_profile ~/.bash_profile
ln -sf $PWD/symbolic/.bashrc ~/.bashrc

ln -sf $PWD/symbolic/.zsh ~/.zsh
ln -sf $PWD/symbolic/.zprofile ~/.zprofile
ln -sf $PWD/symbolic/.zshrc ~/.zshrc

ln -sf $PWD/symbolic/.gitconfig ~/.gitconfig

mkdir -p ~/.config
ln -sf $PWD/symbolic/husky ~/.config

mkdir -p ~/Library/Application\ Support/Code/User
ln -sf $PWD/symbolic/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
