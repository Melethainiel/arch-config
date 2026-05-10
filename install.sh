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

install_dotfiles() {
  install -Dm644 "$DOTFILES_DIR/inputrc" "$HOME/.inputrc"
  install -d "$HOME/.config/ags"
  find "$DOTFILES_DIR/ags" -mindepth 1 -maxdepth 1 \
    ! -name '@girs' \
    ! -name 'node_modules' \
    -exec cp -R -t "$HOME/.config/ags" {} +

  if [[ -d "$DOTFILES_DIR/swaync" ]]; then
    install -d "$HOME/.config/swaync"
    cp -R "$DOTFILES_DIR/swaync/." "$HOME/.config/swaync/"
  fi

  if [[ -d "$DOTFILES_DIR/hypr" ]]; then
    install -d "$HOME/.config/hypr"
    cp -R "$DOTFILES_DIR/hypr/." "$HOME/.config/hypr/"
  fi

  if [[ -d "$DOTFILES_DIR/matugen" ]]; then
    install -d "$HOME/.config/matugen"
    cp -R "$DOTFILES_DIR/matugen/." "$HOME/.config/matugen/"
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
