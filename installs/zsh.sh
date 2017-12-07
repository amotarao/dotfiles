#!/bin/bash

echo "/usr/local/bin/zsh" >> /etc/shells
chsh -s /usr/local/bin/zsh

curl -L http://install.ohmyz.sh | sh
