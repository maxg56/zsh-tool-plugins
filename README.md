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
| [`history`](plugins/history) | Alias `h`, `hl`, `hs`, `hsi` dans `[aliases]` | Aucune |
| [`docker`](plugins/docker) | Les 39 alias dans `[aliases]` ; complétion générée par `docker completion zsh` (ou copiée depuis `legacy/_docker` avant docker 23 ou avec `zstyle ':omz:plugins:docker' legacy-completion yes`) | La complétion est toujours enregistrée par `autoload` + `compdef`, car zsh-tool lance `compinit` après les plugins (Oh My Zsh avant) |
| [`docker-compose`](plugins/docker-compose) | Alias `dco`, `dcup`, `dcl`… vers `docker-compose` ou `docker compose` selon ce qui est installé ; complétion dans `completions/` | Aucune |
| [`kubectl`](plugins/kubectl) | Alias, fonctions `kres`, `kj`, `kjx`, `ky` et complétion, seulement si kubectl est installé (dans `kubectl.zsh`, comme dans Oh My Zsh) | Complétion enregistrée par `autoload` + `compdef` (voir `docker`) |
| [`npm`](plugins/npm) | Alias dans `[aliases]` ; complétion et widget F2 F2 (install ↔ uninstall) dans `npm.zsh` | Aucune |
| [`node`](plugins/node) | Fonction `node-docs` | Définit sa propre copie d'`open_command` (`lib/functions.zsh`), utilisée sauf si l'utilisateur en a une |
| [`nvm`](plugins/nvm) | Chargement de nvm, complétion, options `lazy`, `lazy-cmd`, `autoload`, `silent-autoload` | **Chargement paresseux par défaut** : nvm.sh n'est sourcé qu'au premier appel de `nvm`, `node`, `npm`, `npx`, `pnpm`, `pnpx`, `yarn`, `corepack`, d'une commande de `lazy-cmd` ou de `_omz_nvm_load`. `zstyle ':omz:plugins:nvm' lazy no` rétablit le chargement au démarrage |
| [`python`](plugins/python) | Alias `pyfind`, `pygrep`, `pyserver` dans `[aliases]` ; `py`, `pyclean`, `pyuserpaths`, `vrun`, `mkv`, `PYTHON_AUTO_VRUN` dans `python.zsh` | `add-zsh-hook` est chargé par le plugin lui-même |
| [`pip`](plugins/pip) | Alias dans `[aliases]` ; alias `pip`, fonctions et cache de l'index dans `pip.zsh` ; complétion dans `completions/` | Aucune |
| [`pyenv`](plugins/pyenv) | Chargement de pyenv et pyenv-virtualenv, `pyenv_prompt_info`, réglages `ZSH_PYENV_*` | **Chargement paresseux par défaut** : les shims sont ajoutés à `PATH` sans lancer pyenv, `pyenv init -` est différé jusqu'au premier appel de `pyenv`, `python`, `python3`, `pip`, `pip3`, d'une commande de `zstyle ':omz:plugins:pyenv' lazy-cmd` ou de `_pyenv_plugin_load`. `zstyle ':omz:plugins:pyenv' lazy no` rétablit le comportement d'Oh My Zsh. `pyenv_prompt_info` ne déclenche pas le chargement |
| [`fzf`](plugins/fzf) | Raccourcis et complétion de fzf, quelle que soit l'installation (`fzf --zsh`, Debian, Fedora, `FZF_BASE`…) ; `FZF_DEFAULT_COMMAND` | Le message d'erreur commence par `[zsh-tool]` au lieu de `[oh-my-zsh]` |
| [`command-not-found`](plugins/command-not-found) | `command_not_found_handler` de la distribution (Debian, Arch, Fedora, NixOS, Homebrew…) | Aucune : fichier repris tel quel |
| [`web-search`](plugins/web-search) | Fonction `web_search`, alias `google`, `ddg`, `github`… dans `[aliases]`, moteurs de `ZSH_WEB_SEARCH_ENGINES` | Copies d'`open_command` et `omz_urlencode` ; les quatre moteurs d'assistants conversationnels ne sont pas repris (à ajouter avec `ZSH_WEB_SEARCH_ENGINES`) |
| [`copypath`](plugins/copypath) | Fonction `copypath` | Détection du presse-papiers reprise de `lib/clipboard.zsh` (`clipcopy` de l'utilisateur prioritaire) |
| [`dirhistory`](plugins/dirhistory) | Alt+← / Alt+→ dans l'historique des dossiers, Alt+↑ / Alt+↓ dans la hiérarchie ; alias `cde` dans `[aliases]` | Aucune |

## Installation

Copier (ou lier) les dossiers voulus dans le dossier de plugins de zsh-tool, puis les activer dans `~/.config/zsh-tool/config.toml` :

```sh
git clone https://github.com/maxg56/zsh-tool-plugins
mkdir -p ~/.local/share/zsh-tool/plugins
cp -r zsh-tool-plugins/plugins/git ~/.local/share/zsh-tool/plugins/
```

```toml
plugins = ["git", "sudo", "z", "extract", "colored-man-pages", "nvm", "pyenv"]
```

Un plugin natif est prioritaire sur un plugin Oh My Zsh de même nom situé plus loin dans l'ordre de recherche (`~/.local/share/zsh-tool/plugins` est consulté en premier).

## Vérification

`scripts/check.sh` charge chaque plugin dans un `zsh -f` propre via `zsh-tool init zsh`, vérifie ses alias, fonctions et complétions principaux, ainsi qu'un usage réel quand c'est possible (`z`, `extract`, `dirhistory`, `web-search`…), et échoue si quoi que ce soit est écrit sur la sortie d'erreur :

```sh
scripts/check.sh ~/.cargo/bin/zsh-tool
```

Les outils absents de la machine (docker, kubectl, nvm, pyenv, fzf…) sont remplacés par de petits scripts factices créés dans un dossier temporaire : les vérifications n'utilisent pas le réseau. Pour `nvm` et `pyenv`, elles contrôlent que rien n'est chargé au démarrage, que le premier appel charge l'outil puis exécute la commande, et que `lazy no` rétablit le chargement immédiat.

## Licence

MIT, voir [LICENSE](LICENSE). Le code repris d'Oh My Zsh et de Zsh-z reste sous leurs licences MIT respectives, reproduites dans [NOTICE](NOTICE) (et [plugins/z/LICENSE](plugins/z/LICENSE)).
