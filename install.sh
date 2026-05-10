#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$ROOT_DIR/packages"
DOTFILES_DIR="$ROOT_DIR/dotfiles"

PACMAN_LISTS=(
  "$PACKAGES_DIR/core.txt"
  "$PACKAGES_DIR/desktop.txt"
  "$PACKAGES_DIR/gaming.txt"
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

gpu_vendor_detected() {
  local vendor_id="$1"
  local vendor_file

  for vendor_file in /sys/class/drm/card*/device/vendor; do
    [[ -f "$vendor_file" ]] || continue
    grep -qi "^$vendor_id$" "$vendor_file" && return 0
  done

  return 1
}

gaming_gpu_packages() {
  local packages=()

  if gpu_vendor_detected 0x8086; then
    packages+=(vulkan-intel lib32-vulkan-intel)
  fi

  if gpu_vendor_detected 0x1002 || gpu_vendor_detected 0x1022; then
    packages+=(vulkan-radeon lib32-vulkan-radeon)
  fi

  if [[ "${#packages[@]}" -gt 0 ]]; then
    printf '%s\n' "${packages[@]}"
  fi
}

ensure_multilib() {
  if grep -q '^\[multilib\]' /etc/pacman.conf; then
    return
  fi

  if grep -q '^#\[multilib\]' /etc/pacman.conf; then
    sudo sed -i '/^#\[multilib\]/{s/^#//;n;s/^#//;}' /etc/pacman.conf
    return
  fi

  sudo tee -a /etc/pacman.conf >/dev/null <<'EOF'

[multilib]
Include = /etc/pacman.d/mirrorlist
EOF
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

  while IFS= read -r package; do
    packages+=("$package")
  done < <(gaming_gpu_packages)

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

configure_hardware_services() {
  sudo systemctl enable --now bluetooth.service
  sudo systemctl enable --now power-profiles-daemon.service
}

configure_docker() {
  sudo systemctl enable --now docker.service
  sudo usermod -aG docker "$USER"
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

  if [[ -d "$DOTFILES_DIR/fastfetch" ]]; then
    install -d "$HOME/.config/fastfetch"
    cp -R "$DOTFILES_DIR/fastfetch/." "$HOME/.config/fastfetch/"
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
        ! -path "$DOTFILES_DIR/code-oss/User/settings.json" \
        -exec cp -R -t "$HOME/.config/Code" {} +
    fi
  fi

  if [[ -d "$DOTFILES_DIR/sddm" ]]; then
    sudo mkdir -p /etc/sddm.conf.d
    sudo cp -R "$DOTFILES_DIR/sddm/sddm.conf" /etc/sddm.conf.d/sddm.conf
    sudo systemctl enable --now sddm
  fi
}

install_scripts() {
  local script

  for script in "$ROOT_DIR"/scripts/*; do
    [[ -f "$script" ]] || continue
    install -Dm755 "$script" "$HOME/.local/bin/$(basename "$script")"
  done
}

enable_user_services() {
  local services=(
    hyprpolkitagent.service
    hypridle.service
    hyprpaper.service
  )

  systemctl --user enable --now "${services[@]}"
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

  ensure_multilib
  install_pacman_packages
  install_yay
  install_aur_packages
  configure_network
  configure_hardware_services
  configure_docker
  install_dotfiles
  install_scripts
  enable_user_services
  restart_session_components

  printf '\nInstall complete. Reboot or restart Hyprland after validating services and dotfiles.\n'
}

main "$@"
