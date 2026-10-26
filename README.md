# zsh-tool-plugins

Plugins au format natif de [zsh-tool](https://github.com/maxg56/zsh-tool) (`plugin.toml`), portés depuis [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) (commit `d2b7f55`). Ils sont autonomes : aucun ne dépend de `lib/` d'Oh My Zsh.

Le format `plugin.toml` est décrit dans [docs/PLUGIN_TOML.md](https://github.com/maxg56/zsh-tool/blob/main/docs/PLUGIN_TOML.md) du dépôt zsh-tool.

## Plugins

| Plugin | Contenu | Différences avec Oh My Zsh |
| --- | --- | --- |
| [`git`](plugins/git) | Les 204 alias simples dans `[aliases]` ; fonctions (`ggp`, `ggl`, `gccd`, `gbda`…), `compdef` et alias dépendant de la version de git dans `git.zsh` | Définit lui-même `git_current_branch` (repris de `lib/git.zsh`) ; `gbcopy` utilise `clipcopy` s'il existe, sinon détecte l'outil de presse-papiers ; l'alias obsolète `current_branch` n'est pas repris |
| [`sudo`](plugins/sudo) | Widget `sudo-command-line` sur Échap Échap (emacs, viins, vicmd) | Aucune : fichier repris tel quel |
| [`z`](plugins/z) | [Zsh-z](https://github.com/agkozak/zsh-z) : commande `z`, complétion dans `completions/` | Aucune : `zsh-z.zsh` est le `z.plugin.zsh` d'Oh My Zsh, inchangé |
| [`extract`](plugins/extract) | Fonction `extract`, alias `x` dans `[aliases]`, complétion dans `completions/` | Aucune |
| [`colored-man-pages`](plugins/colored-man-pages) | Fonctions `colored`, `man`, `dman`, `debman` | Les séquences de couleur sont écrites directement au lieu de venir de la fonction `colors` chargée par `lib/` |

## Installation

Copier (ou lier) les dossiers voulus dans le dossier de plugins de zsh-tool, puis les activer dans `~/.config/zsh-tool/config.toml` :

```sh
git clone https://github.com/maxg56/zsh-tool-plugins
mkdir -p ~/.local/share/zsh-tool/plugins
cp -r zsh-tool-plugins/plugins/git ~/.local/share/zsh-tool/plugins/
```

```toml
plugins = ["git", "sudo", "z", "extract", "colored-man-pages"]
```

Un plugin natif est prioritaire sur un plugin Oh My Zsh de même nom situé plus loin dans l'ordre de recherche (`~/.local/share/zsh-tool/plugins` est consulté en premier).

## Vérification

`scripts/check.sh` charge chaque plugin dans un `zsh -f` propre via `zsh-tool init zsh`, vérifie ses alias et fonctions principaux (et, pour `z` et `extract`, un usage réel) et échoue si quoi que ce soit est écrit sur la sortie d'erreur :

```sh
scripts/check.sh ~/.cargo/bin/zsh-tool
```

## Licence

MIT, voir [LICENSE](LICENSE). Le code repris d'Oh My Zsh et de Zsh-z reste sous leurs licences MIT respectives, reproduites dans [NOTICE](NOTICE) (et [plugins/z/LICENSE](plugins/z/LICENSE)).
