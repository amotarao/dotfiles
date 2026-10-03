「好きなようにつくる」

```
git clone git@github.com:amotarao/dotfiles.git
cd dotfiles
./install.sh
```

dotfiles は [chezmoi](https://www.chezmoi.io/) で管理しています。`home/` 以下がホームディレクトリに配置されます。

```
chezmoi diff   # 差分の確認
chezmoi apply  # 反映
```

VS Code の `settings.json` は `vscode/settings.json` へのシンボリックリンクとして配置されます。
