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
│   ├── fastfetch/
│   ├── matugen/
│   ├── swaync/
│   └── inputrc
├── scripts/
│   ├── arch-menu
│   └── theme-switch
└── packages/
    ├── core.txt
    ├── desktop.txt
    ├── gaming.txt
    ├── aur.txt
    └── dev.txt
```

## Paquets

- `packages/core.txt` contient le socle commun de tous les PC, dont `mise` et `zoxide`. L'installation configure aussi Node.js LTS en global via `mise`.
- `packages/desktop.txt` contient la session Hyprland, Waybar en fallback, iwd/Impala, Plymouth, polices et apps desktop de base comme GNOME Disks et Discord.
- `packages/gaming.txt` contient Steam et Gamescope. Le script active `[multilib]` et detecte les paquets Vulkan/lib32 Intel ou AMD comme Omarchy.
- `packages/aur.txt` contient les paquets AUR, notamment AGS via `aylurs-gtk-shell-git` et OpenCode.
- `packages/dev.txt` contient les outils dev optionnels comme Docker.
- Howdy est optionnel, car il depend d'une camera IR. Il se configure depuis le menu `Setup > Security > Face unlock`.

## Lancement

```bash
./install.sh
```

Le script doit etre lance avec l'utilisateur normal, pas avec `root`.

## Reseau

La stack retenue est `iwd + Impala`.

Le script active `iwd` et desactive `NetworkManager` et `wpa_supplicant` si ces services existent, pour eviter que plusieurs gestionnaires Wi-Fi se battent entre eux.

## Plymouth

Le script installe `plymouth`, `cantarell-fonts`, telecharge le theme Arch `arch-mac-style` depuis <https://www.gnome-look.org/p/2106821>, l'installe dans `/usr/share/plymouth/themes/`, ajoute le hook `plymouth` ou `sd-plymouth` dans `/etc/mkinitcpio.conf`, regenere les initramfs/UKI avec `mkinitcpio -P`, puis ajoute `quiet splash` aux entrees systemd-boot presentes dans `/boot/loader/entries`, a `/etc/kernel/cmdline` pour les UKI systemd-stub, ou a `GRUB_CMDLINE_LINUX_DEFAULT` si GRUB est utilise.

Avec SDDM, l'installateur active `sddm-plymouth.service` quand l'unite existe afin de garder une transition propre entre le splash et l'ecran de connexion.

## Docker

Le script installe Docker, active `docker.service` et ajoute l'utilisateur courant au groupe `docker`.

La nouvelle appartenance au groupe est prise en compte apres reconnexion.

## Howdy

Howdy est optionnel, car il ne fonctionne correctement que sur les machines avec camera IR. Le setup est lance depuis `arch-menu` :

```text
Setup > Security > Face unlock
```

Le script installe `howdy-git`, affiche les chemins camera detectes, ouvre `sudo howdy config`, ajoute le modele visage, puis configure PAM pour `sudo` et `hyprlock` uniquement. La ligne ajoutee est volontairement limitee a ces services :

```pam
auth        sufficient  pam_howdy.so
```

Si la reconnaissance echoue ou expire, PAM continue vers l'authentification classique et demande le mot de passe.

La configuration camera reste specifique a chaque machine. Sur le Zenbook, le flux IR teste est :

```text
/dev/v4l/by-path/pci-0000:00:14.0-usb-0:5:1.2-video-index0
```

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

## Menu Systeme

`SUPER+ALT+SPACE` ouvre `arch-menu`, un menu Fuzzel pour lancer les apps, afficher About via Fastfetch, acceder au setup, verrouiller, suspendre, quitter Hyprland, redemarrer ou eteindre.

`SUPER+SHIFT+I` active/desactive `hypridle` pour la session courante.

Les scripts de `scripts/` sont installes dans `~/.local/bin`.

## Themes

`matugen` genere les couleurs depuis un wallpaper pour AGS, SwayNC, Hyprland, Ghostty, Fuzzel, GTK et VS Code (via l'extension Material Code). La configuration Hyprland 0.55+ est en Lua avec `dotfiles/hypr/hyprland.lua` et ses modules.

Apres installation, lancer :

```bash
theme-switch /chemin/vers/wallpaper.jpg
```

Le repo inclut aussi des presets fixes. Pour appliquer Nord sur Ghostty, Hyprland, Fuzzel, AGS, SwayNC, GTK, VS Code, OpenCode et son premier wallpaper :

```bash
theme-switch nord
```

Le script genere les fichiers de theme dans `~/.config/ags`, `~/.config/swaync`, `~/.config/hypr`, `~/.config/ghostty`, `~/.config/fuzzel` et `~/.config/gtk-*`, ecrit aussi `~/.config/hypr/hyprpaper.conf` pour que le wallpaper persiste au reboot, tente de le synchroniser avec le theme Pixie de SDDM, puis recharge les composants de session. Cote Hyprland, le theme genere est `~/.config/hypr/theme.lua`.

## Shell

`dotfiles/inputrc` configure les fleches haut/bas pour rechercher dans l'historique a partir du debut deja tape.

Exemple : apres avoir tape `z ar`, fleche haut remonte uniquement les commandes qui commencent par `z ar`.

Le script ajoute aussi `~/.local/bin` au `PATH` dans `~/.bash_profile` et `~/.bashrc`, afin que les scripts installes depuis `scripts/` soient disponibles dans les terminaux interactifs et les lanceurs qui passent par `bash -lc`.
