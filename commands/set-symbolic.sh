#!/bin/bash

ln -sf $PWD/symbolic/.gitconfig ~/.gitconfig
mkdir -p ~/.config
ln -sf $PWD/symbolic/fish ~/.config
mkdir -p ~/Library/Application\ Support/Code/User
ln -sf $PWD/symbolic/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
