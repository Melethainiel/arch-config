#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$ROOT_DIR/packages"
DOTFILES_DIR="$ROOT_DIR/dotfiles"
THEMES_DIR="$ROOT_DIR/themes"

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

ensure_pacman_repo() {
  local repo="$1"

  if grep -q "^\[$repo\]" /etc/pacman.conf; then
    return
  fi

  if grep -q "^#\[$repo\]" /etc/pacman.conf; then
    sudo sed -i "/^#\[$repo\]/{s/^#//;n;s/^#//;}" /etc/pacman.conf
    return
  fi

  sudo tee -a /etc/pacman.conf >/dev/null <<EOF

[$repo]
Include = /etc/pacman.d/mirrorlist
EOF
}

ensure_pacman_repos() {
  ensure_pacman_repo extra
  ensure_pacman_repo multilib
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
  sudo mkdir -p /etc/iwd
  sudo tee /etc/iwd/main.conf >/dev/null <<EOF
[General]
EnableNetworkConfiguration=true

[Network]
NameResolvingService=systemd
EOF

  sudo systemctl enable --now systemd-resolved.service
  sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

  sudo mkdir -p /etc/systemd/network
  sudo cp "$DOTFILES_DIR/systemd-network/20-wired.network" /etc/systemd/network/
  sudo systemctl enable --now systemd-networkd.service

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

configure_mise() {
  command -v mise >/dev/null 2>&1 || die "mise is required to install global tools"

  mise use --global --yes node@lts
}

configure_shell_path() {
  local bash_profile="$HOME/.bash_profile"
  local bashrc="$HOME/.bashrc"
  local local_bin_marker="# arch-config local bin"
  local mise_shims_marker="# arch-config mise shims"

  touch "$bash_profile"
  touch "$bashrc"

  if ! grep -qF "$local_bin_marker" "$bash_profile"; then
    {
      printf '\n%s\n' "$local_bin_marker"
      printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    } >>"$bash_profile"
  fi

  if ! grep -qF "$local_bin_marker" "$bashrc"; then
    {
      printf '\n%s\n' "$local_bin_marker"
      printf 'export PATH="$HOME/.local/bin:$PATH"\n'
    } >>"$bashrc"
  fi

  if ! grep -qF "$mise_shims_marker" "$bash_profile"; then
    {
      printf '\n%s\n' "$mise_shims_marker"
      printf 'export PATH="$HOME/.local/share/mise/shims:$PATH"\n'
    } >>"$bash_profile"
  fi

  if ! grep -qF "$mise_shims_marker" "$bashrc"; then
    {
      printf '\n%s\n' "$mise_shims_marker"
      printf 'export PATH="$HOME/.local/share/mise/shims:$PATH"\n'
    } >>"$bashrc"
  fi
}

should_overwrite_applied_theme() {
  local answer

  if [[ ! -f "$HOME/.config/ags/theme.css" ]] \
    && [[ ! -f "$HOME/.config/swaync/theme.css" ]] \
    && [[ ! -f "$HOME/.config/hypr/theme.lua" ]] \
    && [[ ! -f "$HOME/.config/hypr/theme.conf" ]] \
    && [[ ! -f "$HOME/.config/ghostty/theme.conf" ]] \
    && [[ ! -f "$HOME/.config/ghostty/themes/Matugen" ]] \
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

cleanup_legacy_hyprland_conf() {
  local hypr_dir="$HOME/.config/hypr"

  rm -f \
    "$hypr_dir/hyprland.conf" \
    "$hypr_dir/monitors.conf" \
    "$hypr_dir/programs.conf" \
    "$hypr_dir/autostart.conf" \
    "$hypr_dir/environment.conf" \
    "$hypr_dir/permissions.conf" \
    "$hypr_dir/appearance.conf" \
    "$hypr_dir/layout.conf" \
    "$hypr_dir/windowrules.conf" \
    "$hypr_dir/input.conf" \
    "$hypr_dir/keybindings.conf" \
    "$hypr_dir/hyprland-gui.conf" \
    "$hypr_dir/theme.conf"
}

install_dotfiles() {
  local overwrite_theme=0

  if should_overwrite_applied_theme; then
    overwrite_theme=1
  fi

  install -Dm644 "$DOTFILES_DIR/inputrc" "$HOME/.inputrc"

  if [[ -d "$DOTFILES_DIR/environment.d" ]]; then
    install -d "$HOME/.config/environment.d"
    cp -R "$DOTFILES_DIR/environment.d/." "$HOME/.config/environment.d/"
    systemctl --user import-environment PATH >/dev/null 2>&1 || true
  fi

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
    cleanup_legacy_hyprland_conf
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/hypr/." "$HOME/.config/hypr/"
    else
      find "$DOTFILES_DIR/hypr" -mindepth 1 -maxdepth 1 \
        ! -name 'theme.lua' \
        -exec cp -R -t "$HOME/.config/hypr" {} +
      if [[ ! -f "$HOME/.config/hypr/theme.lua" ]]; then
        cp -R "$DOTFILES_DIR/hypr/theme.lua" "$HOME/.config/hypr/"
      fi
    fi
  fi

  if [[ -d "$DOTFILES_DIR/matugen" ]]; then
    install -d "$HOME/.config/matugen"
    cp -R "$DOTFILES_DIR/matugen/." "$HOME/.config/matugen/"
    rm -f "$HOME/.config/matugen/templates/hyprland-theme.conf"
  fi

  if [[ -d "$DOTFILES_DIR/voxtype" ]]; then
    install -d "$HOME/.config/voxtype"
    cp -R "$DOTFILES_DIR/voxtype/." "$HOME/.config/voxtype/"
  fi

  if [[ -d "$DOTFILES_DIR/ghostty" ]]; then
    install -d "$HOME/.config/ghostty/themes"
    if [[ "$overwrite_theme" -eq 1 ]]; then
      cp -R "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/"
      cp -R "$DOTFILES_DIR/ghostty/theme.conf" "$HOME/.config/ghostty/"
      cp -R "$DOTFILES_DIR/ghostty/theme.conf" "$HOME/.config/ghostty/themes/Matugen"
    else
      cp -R "$DOTFILES_DIR/ghostty/config" "$HOME/.config/ghostty/"
      if [[ ! -f "$HOME/.config/ghostty/theme.conf" ]]; then
        cp -R "$DOTFILES_DIR/ghostty/theme.conf" "$HOME/.config/ghostty/"
      fi
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

install_themes() {
  if [[ -d "$THEMES_DIR" ]]; then
    install -d "$HOME/.config/arch-config/themes"
    cp -R "$THEMES_DIR/." "$HOME/.config/arch-config/themes/"
  fi
}

configure_voxtype() {
  local answer

  command -v voxtype >/dev/null 2>&1 || return 0

  systemctl --user enable voxtype.service >/dev/null 2>&1 || true
  systemctl --user restart voxtype.service >/dev/null 2>&1 || true

  if [[ ! -t 0 ]]; then
    printf 'Voxtype installed. Run arch-setup-voxtype later to download the speech model.\n'
    return 0
  fi

  read -r -p "Download Voxtype speech model now? [Y/n] " answer || answer=n

  case "$answer" in
    ""|[Yy]|[Yy][Ee][Ss]) "$HOME/.local/bin/arch-setup-voxtype" ;;
    *) printf 'Skipped Voxtype model download. Run arch-setup-voxtype later.\n' ;;
  esac
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

  ensure_pacman_repos
  install_pacman_packages
  install_yay
  install_aur_packages
  configure_network
  configure_hardware_services
  configure_docker
  configure_mise
  configure_shell_path
  install_dotfiles
  install_scripts
  install_themes
  configure_voxtype
  enable_user_services
  restart_session_components

  printf '\nInstall complete. Reboot or restart Hyprland after validating services and dotfiles.\n'
}

main "$@"
