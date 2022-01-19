#!/bin/bash

ln -sf $PWD/symbolic/.gitconfig ~/.gitconfig
ln -sf $PWD/symbolic/.bash_profile ~/.bash_profile
ln -sf $PWD/symbolic/.bashrc ~/.bashrc

# mkdir -p ~/.config
# ln -sf $PWD/symbolic/fish ~/.config

mkdir -p ~/Library/Application\ Support/Code/User
ln -sf $PWD/symbolic/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
