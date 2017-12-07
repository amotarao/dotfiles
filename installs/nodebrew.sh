#!/bin/bash

if test ! $(which node); then
	echo "Installing nodebrew."
	curl -L git.io/nodebrew | perl - setup
else
	echo "Node.js is already installed."
fi

nodebrew install-binary stable
