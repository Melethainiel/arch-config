# Arch Config

Installation reproductible pour une base Arch + Hyprland personnelle.

L'objectif est d'avoir le meme socle sur chaque PC sans construire un installateur monolithique ni multiplier les fichiers.

## Structure

```text
.
├── install.sh
├── dotfiles/
│   ├── ags/
│   │   ├── app.tsx
│   │   ├── env.d.ts
│   │   ├── lib/
│   │   ├── widgets/
│   │   ├── tsconfig.json
│   │   └── style.css
│   ├── hypr/
│   ├── matugen/
│   ├── swaync/
│   └── inputrc
├── scripts/
│   └── theme-switch
└── packages/
    ├── core.txt
    ├── desktop.txt
    ├── aur.txt
    └── dev.txt
```

## Paquets

- `packages/core.txt` contient le socle commun de tous les PC, dont `mise`.
- `packages/desktop.txt` contient la session Hyprland, Waybar en fallback, iwd/Impala, polices et apps desktop de base.
- `packages/aur.txt` contient les paquets AUR, notamment AGS via `aylurs-gtk-shell-git`.
- `packages/dev.txt` reste disponible pour de futurs outils optionnels.

## Lancement

```bash
./install.sh
```

Le script doit etre lance avec l'utilisateur normal, pas avec `root`.

## Reseau

La stack retenue est `iwd + Impala`.

Le script active `iwd` et desactive `NetworkManager` et `wpa_supplicant` si ces services existent, pour eviter que plusieurs gestionnaires Wi-Fi se battent entre eux.

## AGS

Le bon paquet AGS/Aylur est :

```text
aylurs-gtk-shell-git
```

Ne pas installer `aur/ags`: c'est Adventure Game Studio.

Waybar reste installe comme fallback tant que la barre AGS n'est pas validee sur la machine.

Pour que VS Code resolve les imports AGS dans `dotfiles/ags`, lancer si besoin :

```bash
ags types --directory dotfiles/ags --update
```

Cette commande genere `dotfiles/ags/@girs` et `dotfiles/ags/node_modules`, ignores par Git.

## Barre

La barre active est AGS (`dotfiles/ags`). Elle est composee de bulles separees en haut : logo Arch, lecture en cours et meteo a gauche, date/heure et workspaces au centre, volume/reseau/batterie/notifications a droite.

## Themes

`matugen` genere les couleurs depuis un wallpaper pour AGS, SwayNC et Hyprland sans migrer Hyprland vers Lua.

Apres installation, lancer :

```bash
theme-switch /chemin/vers/wallpaper.jpg
```

Le script genere `~/.config/ags/theme.css`, `~/.config/swaync/theme.css` et `~/.config/hypr/theme.conf`, applique le wallpaper via `hyprpaper` si possible, puis recharge AGS, SwayNC et Hyprland.

## Shell

`dotfiles/inputrc` configure les fleches haut/bas pour rechercher dans l'historique a partir du debut deja tape.

Exemple : apres avoir tape `z ar`, fleche haut remonte uniquement les commandes qui commencent par `z ar`.
