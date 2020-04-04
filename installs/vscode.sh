#!/bin/bash

cat $PWD/configs/vscode-extensions.txt | while read line
do
 code --install-extension $line
done

code --list-extensions > $PWD/configs/vscode-extensions.txt
