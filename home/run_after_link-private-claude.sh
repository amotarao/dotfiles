#!/bin/bash

# private リポジトリ (.chezmoiexternal.toml) の設定・スキルを ~/.claude にリンクする
setup="$HOME/works/amon/my-dot-claude/setup-claude-symlinks.sh"

if [ -x "$setup" ]; then
  "$setup"
fi
