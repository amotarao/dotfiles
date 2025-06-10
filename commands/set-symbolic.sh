#!/bin/bash

ln -sf $PWD/symbolic/.gitconfig ~/.gitconfig
ln -sf $PWD/symbolic/.bash_profile ~/.bash_profile
ln -sf $PWD/symbolic/.bashrc ~/.bashrc
ln -sf $PWD/symbolic/.profile ~/.profile

mkdir -p ~/.config
ln -sf $PWD/symbolic/fish ~/.config
ln -sf $PWD/symbolic/husky ~/.config
ln -sf $PWD/symbolic/omf ~/.config

mkdir -p ~/Library/Application\ Support/Code/User
ln -sf $PWD/symbolic/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf $PWD/symbolic/cursor/settings.json ~/Library/Application\ Support/Cursor/User/settings.json
