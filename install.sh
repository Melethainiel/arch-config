#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$ROOT_DIR/packages"
DOTFILES_DIR="$ROOT_DIR/dotfiles"

PACMAN_LISTS=(
  "$PACKAGES_DIR/core.txt"
  "$PACKAGES_DIR/desktop.txt"
  "$PACKAGES_DIR/dev.txt"
)

AUR_LIST="$PACKAGES_DIR/aur.txt"

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

read_packages() {
  local file="$1"

  [[ -f "$file" ]] || die "missing package list: $file"

  sed -e 's/#.*//' -e '/^[[:space:]]*$/d' "$file"
}

require_arch() {
  [[ -f /etc/arch-release ]] || die "this installer is intended for Arch Linux"
}

require_user() {
  [[ "${EUID}" -ne 0 ]] || die "run this script as your user, not as root"
}

install_pacman_packages() {
  local packages=()
  local file package

  for file in "${PACMAN_LISTS[@]}"; do
    while IFS= read -r package; do
      packages+=("$package")
    done < <(read_packages "$file")
  done

  if [[ "${#packages[@]}" -gt 0 ]]; then
    sudo pacman -Syu --needed --noconfirm "${packages[@]}"
  fi
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  local build_dir
  build_dir="$(mktemp -d)"
  trap 'rm -rf "$build_dir"' RETURN

  git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
  (cd "$build_dir/yay" && makepkg -si --noconfirm)
}

install_aur_packages() {
  local packages=()
  local package

  while IFS= read -r package; do
    packages+=("$package")
  done < <(read_packages "$AUR_LIST")

  if [[ "${#packages[@]}" -gt 0 ]]; then
    yay -S --needed --noconfirm "${packages[@]}"
  fi
}

configure_network() {
  sudo systemctl enable --now iwd.service

  # Keep one Wi-Fi backend. These commands are tolerant when units are absent.
  sudo systemctl disable --now NetworkManager.service 2>/dev/null || true
  sudo systemctl disable --now wpa_supplicant.service 2>/dev/null || true
}

should_overwrite_applied_theme() {
  local answer

  if [[ ! -f "$HOME/.config/ags/theme.css" ]] \
    && [[ ! -f "$HOME/.config/swaync/theme.css" ]] \
    && [[ ! -f "$HOME/.config/hypr/theme.conf" ]] \
    && [[ ! -f "$HOME/.config/ghostty/theme.conf" ]] \
    && [[ ! -f "$HOME/.config/fuzzel/fuzzel.ini" ]] \
    && [[ ! -f "$HOME/.config/gtk-3.0/gtk.css" ]] \
    && [[ ! -f "$HOME/.config/gtk-4.0/gtk.css" ]]; then
    return 0
  fi

  read -r -p "A generated theme already exists. Overwrite it with dotfile defaults? [y/N] " answer

  case "$answer" in
    [Yy]|[Yy][Ee][Ss]) return 0 ;;
    *) return 1 ;;
  esac
}

install_dotfiles() {
  local overwrite_theme=0

  if should_overwrite_applied_theme; then
    overwrite_theme=1
  fi

  install -Dm644 "$DOTFILES_DIR/inputrc" "$HOME/.inputrc"
  install -d "$HOME/.config/ags"
  if [[ "$overwrite_theme" -eq 1 ]]; then
    find "$DOTFILES_DIR/ags" -mindepth 1 -maxdepth 1 \
      ! -name '@girs' \
      ! -name 'node_modules' \
      -exec cp -R -t "$HOME/.config/ags" {} +
  else
    find "$DOTFILES_DIR/ags" -mindepth 1 -maxdepth 1 \
      ! -name '@girs' \
      ! -name 'node_modules' \
      ! -name 'theme.css' \
      -exec cp -R -t "$HOME/.config/ags" {} +
  fi

  if [[ -d "$DOTFILES_DIR/swaync" ]]; then
    install -d "$HOME/.config/swaync"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/swaync/." "$HOME/.config/swaync/"
    else
      find "$DOTFILES_DIR/swaync" -mindepth 1 -maxdepth 1 \
        ! -name 'theme.css' \
        -exec cp -R -t "$HOME/.config/swaync" {} +
    fi
  fi

  if [[ -d "$DOTFILES_DIR/hypr" ]]; then
    install -d "$HOME/.config/hypr"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/hypr/." "$HOME/.config/hypr/"
    else
      find "$DOTFILES_DIR/hypr" -mindepth 1 -maxdepth 1 \
        ! -name 'theme.conf' \
        -exec cp -R -t "$HOME/.config/hypr" {} +
    fi
  fi

  if [[ -d "$DOTFILES_DIR/matugen" ]]; then
    install -d "$HOME/.config/matugen"
    cp -R "$DOTFILES_DIR/matugen/." "$HOME/.config/matugen/"
  fi

  if [[ -d "$DOTFILES_DIR/ghostty" ]]; then
    install -d "$HOME/.config/ghostty/themes"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/"
      cp -R "$DOTFILES_DIR/ghostty/theme.conf" "$HOME/.config/ghostty/themes/Matugen"
    else
      cp -R "$DOTFILES_DIR/ghostty/config.ghostty" "$HOME/.config/ghostty/"
      if [[ ! -f "$HOME/.config/ghostty/themes/Matugen" ]]; then
        cp -R "$DOTFILES_DIR/ghostty/theme.conf" "$HOME/.config/ghostty/themes/Matugen"
      fi
    fi
  fi

  if [[ -d "$DOTFILES_DIR/fuzzel" ]]; then
    install -d "$HOME/.config/fuzzel"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/fuzzel/." "$HOME/.config/fuzzel/"
    elif [[ ! -f "$HOME/.config/fuzzel/fuzzel.ini" ]]; then
      cp -R "$DOTFILES_DIR/fuzzel/." "$HOME/.config/fuzzel/"
    fi
  fi

  if [[ -d "$DOTFILES_DIR/gtk-3.0" ]]; then
    install -d "$HOME/.config/gtk-3.0"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/gtk-3.0/." "$HOME/.config/gtk-3.0/"
    else
      find "$DOTFILES_DIR/gtk-3.0" -mindepth 1 -maxdepth 1 \
        ! -name 'gtk.css' \
        -exec cp -R -t "$HOME/.config/gtk-3.0" {} +
    fi
  fi

  if [[ -d "$DOTFILES_DIR/gtk-4.0" ]]; then
    install -d "$HOME/.config/gtk-4.0"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/gtk-4.0/." "$HOME/.config/gtk-4.0/"
    else
      find "$DOTFILES_DIR/gtk-4.0" -mindepth 1 -maxdepth 1 \
        ! -name 'gtk.css' \
        -exec cp -R -t "$HOME/.config/gtk-4.0" {} +
    fi
  fi

  if [[ -d "$DOTFILES_DIR/code-oss" ]]; then
    install -d "$HOME/.config/Code"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/code-oss/." "$HOME/.config/Code"
    else
      find "$DOTFILES_DIR/code-oss" -mindepth 1 -maxdepth 1 \
        ! -name 'User/settings.json' \
        -exec cp -R -t "$HOME/.config/Code" {} +
    fi
  fi

  if [[ -f "$ROOT_DIR/scripts/theme-switch" ]]; then
    install -Dm755 "$ROOT_DIR/scripts/theme-switch" "$HOME/.local/bin/theme-switch"
  fi
}

restart_session_components() {
  local answer

  read -r -p "Restart AGS and reload Hyprland now? [Y/n] " answer

  case "$answer" in
    ""|[Yy]|[Yy][Ee][Ss]) ;;
    *) return ;;
  esac

  if command -v ags >/dev/null 2>&1; then
    ags quit --instance arch-shell >/dev/null 2>&1 || true
    pkill -x ags >/dev/null 2>&1 || true
    sleep 1
    ags run "$HOME/.config/ags/app.tsx" >/tmp/arch-config-ags.log 2>&1 &
  fi

  if command -v swaync >/dev/null 2>&1; then
    systemctl --user stop dunst.service >/dev/null 2>&1 || true
    pkill -x swaync >/dev/null 2>&1 || true
    swaync >/tmp/arch-config-swaync.log 2>&1 &
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true
  fi
}

main() {
  require_arch
  require_user

  install_pacman_packages
  install_yay
  install_aur_packages
  configure_network
  install_dotfiles
  restart_session_components

  printf '\nInstall complete. Reboot or restart Hyprland after validating services and dotfiles.\n'
}

main "$@"
