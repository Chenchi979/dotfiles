#!/usr/bin/env bash
# =============================================================================
#  install.sh · dotfiles de phant0m (Parrot OS / Kali Linux)
#
#  bspwm · sxhkd · kitty · polybar · picom · rofi · dunst
#  zsh + powerlevel10k + plugins · lsd · batcat · neovim + NvChad
#
#  Uso:   ./install.sh          (como tu usuario, NO con sudo)
#         ./install.sh -y       (sin preguntar)
#         ./install.sh --help
#
#  Se puede ejecutar todas las veces que quieras: lo que ya está, lo deja.
#  Lo que pisa, lo guarda antes en ~/.dotfiles-backup/<fecha>/
# =============================================================================

set -uo pipefail

#-------------------------------- variables ----------------------------------
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODULES=(bspwm sxhkd kitty picom polybar rofi dunst zsh)
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
LOG="$HOME/.dotfiles-install.log"
NVIM_MIN="0.10"
ASSUME_YES=0
FORCE=0
WARNINGS=()

#-------------------------------- colores ------------------------------------
if [[ -t 1 ]]; then
  R=$'\e[31m' G=$'\e[32m' Y=$'\e[33m' B=$'\e[34m' M=$'\e[35m' N=$'\e[0m' BOLD=$'\e[1m'
else
  R='' G='' Y='' B='' M='' N='' BOLD=''
fi

step() { printf '\n%s==>%s %s%s%s\n' "$B" "$N" "$BOLD" "$*" "$N"; echo "==> $*" >>"$LOG"; }
ok()   { printf '  %s✔%s %s\n' "$G" "$N" "$*"; echo "  OK  $*" >>"$LOG"; }
info() { printf '  %s•%s %s\n' "$M" "$N" "$*"; echo "  ..  $*" >>"$LOG"; }
warn() { printf '  %s!%s %s\n' "$Y" "$N" "$*"; echo "  !!  $*" >>"$LOG"; WARNINGS+=("$*"); }
die()  { printf '\n%s✘ %s%s\n' "$R" "$*" "$N" >&2; echo "  XX  $*" >>"$LOG"; exit 1; }

# Ejecuta un comando y guarda su salida en el log (no ensucia la pantalla)
quiet() { "$@" >>"$LOG" 2>&1; }

# ¿Está instalada la fuente? (sin "| grep -q": con pipefail daría falso error por SIGPIPE)
has_font() { [[ "$(fc-list : family 2>/dev/null)" == *"Hack Nerd Font"* ]]; }

# Compara versiones: ver_ge 0.11.2 0.10 -> verdadero
ver_ge() { [[ "$(printf '%s\n%s\n' "$2" "$1" | sort -V | head -n1)" == "$2" ]]; }

usage() {
  sed -n '3,14p' "$0" | sed 's/^# \{0,1\}//'
  cat <<EOF
  Opciones:
    -y, --yes     no pide confirmación
    --force       permite instalar en otra distro basada en Debian (no probado)
    -h, --help    esta ayuda
EOF
  exit 0
}

#-------------------------------- argumentos ---------------------------------
for arg in "$@"; do
  case "$arg" in
    -y|--yes) ASSUME_YES=1 ;;
    --force)  FORCE=1 ;;
    -h|--help) usage ;;
    *) die "Opción desconocida: $arg (usa --help)" ;;
  esac
done

: >"$LOG"
echo "install.sh · $(date) · $DOTFILES" >>"$LOG"

# =============================================================================
#  0. Comprobaciones previas
# =============================================================================
check_system() {
  step "Comprobando el sistema"

  [[ $EUID -eq 0 ]] && die "No lo ejecutes como root ni con sudo. Hazlo como tu usuario: ./install.sh"

  command -v apt-get >/dev/null || die "No hay apt. Este instalador es para Parrot OS y Kali Linux."

  local id="desconocida"
  [[ -r /etc/os-release ]] && id="$(. /etc/os-release; echo "${ID:-desconocida}")"
  case "$id" in
    parrot|kali) ok "Distro: $(. /etc/os-release; echo "$PRETTY_NAME")" ;;
    *) if (( FORCE )); then warn "Distro '$id' no probada; sigo por --force"
       else die "Distro '$id' no soportada (solo Parrot y Kali). Si sabes lo que haces: ./install.sh --force"; fi ;;
  esac

  [[ "$(uname -m)" == "x86_64" ]] || warn "Arquitectura $(uname -m): Neovim y la fuente se descargan para x86_64"

  command -v sudo >/dev/null || die "Falta sudo"
  info "Pido tu contraseña de sudo una vez:"
  sudo -v || die "Sin permisos de sudo"
  # Mantener sudo vivo mientras dura el script
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
  SUDO_KEEPALIVE=$!
  trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null' EXIT

  for m in "${MODULES[@]}"; do
    [[ -d "$DOTFILES/$m" ]] || die "Falta la carpeta '$m' en $DOTFILES. ¿Has clonado el repo entero?"
  done
  ok "Repo completo en $DOTFILES"

  VIRT="$(systemd-detect-virt 2>/dev/null || echo none)"
  [[ "$VIRT" != "none" ]] && info "Máquina virtual detectada: $VIRT"
}

confirm() {
  (( ASSUME_YES )) && return 0
  cat <<EOF

  Se va a hacer lo siguiente:
    1. Instalar paquetes con apt (packages/apt.txt)
    2. Instalar Hack Nerd Font, powerlevel10k, plugin sudo de zsh
    3. Instalar Neovim >= $NVIM_MIN y NvChad (si no los tienes)
    4. Enlazar las configs en ~/.config (copia de lo que exista en ~/.dotfiles-backup/)
    5. Configurar zsh para ti y para root, y ponerlo como shell por defecto
    6. Añadir bspwm a la pantalla de inicio de sesión

EOF
  read -r -p "  ¿Continuar? [s/N] " r
  [[ "$r" =~ ^[sSyY]$ ]] || die "Cancelado. No se ha tocado nada."
}

# =============================================================================
#  1. Paquetes
# =============================================================================
install_packages() {
  step "Instalando paquetes (puede tardar unos minutos)"

  info "Actualizando la lista de paquetes"
  quiet sudo apt-get update || warn "apt-get update dio errores (mira $LOG)"

  local wanted=() available=() missing=()
  mapfile -t wanted < <(grep -vE '^\s*(#|$)' "$DOTFILES/packages/apt.txt" | awk '{print $1}')

  # Herramientas de VMware solo si estamos en VMware
  [[ "$VIRT" == "vmware" ]] && wanted+=(open-vm-tools-desktop)

  for p in "${wanted[@]}"; do
    if [[ -n "$(apt-cache policy "$p" 2>/dev/null | awk '/Candidate:/ && $2 != "(none)" {print $2}')" ]]; then
      available+=("$p")
    else
      missing+=("$p")
    fi
  done

  if quiet sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${available[@]}"; then
    ok "${#available[@]} paquetes instalados o ya presentes"
  else
    warn "apt dio errores instalando paquetes (mira $LOG)"
  fi

  for p in "${missing[@]}"; do
    case "$p" in
      lsd) install_lsd_from_github ;;
      *)   warn "El paquete '$p' no existe en tus repos; se ha saltado" ;;
    esac
  done
}

install_lsd_from_github() {
  command -v lsd >/dev/null && { ok "lsd ya instalado"; return; }
  info "lsd no está en apt; lo bajo de GitHub (lsd-rs/lsd)"
  local url tmp
  url="$(curl -fsSL https://api.github.com/repos/lsd-rs/lsd/releases/latest \
        | grep -oE 'https://[^"]+lsd_[0-9.]+_amd64\.deb' | head -n1)"
  [[ -z "$url" ]] && { warn "No encontré el .deb de lsd en GitHub"; return; }
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/lsd.deb" "$url" && quiet sudo apt-get install -y "$tmp/lsd.deb"; then
    ok "lsd instalado desde GitHub"
  else
    warn "No se pudo instalar lsd"
  fi
  rm -rf "$tmp"
}

# =============================================================================
#  2. Fuente, powerlevel10k y plugin sudo
# =============================================================================
install_font() {
  step "Hack Nerd Font"
  if has_font; then
    ok "Ya instalada"; return
  fi
  local dir="$HOME/.local/share/fonts/HackNerdFont" tmp
  tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/Hack.zip" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Hack.zip; then
    mkdir -p "$dir"
    quiet unzip -o "$tmp/Hack.zip" -d "$dir" -x 'LICENSE*' 'README*'
    quiet fc-cache -f
    has_font && ok "Instalada en $dir" || warn "La fuente no aparece en fc-list"
  else
    warn "No se pudo descargar Hack Nerd Font (sin iconos hasta que la instales)"
  fi
  rm -rf "$tmp"
}

install_p10k() {
  step "powerlevel10k y plugin sudo"
  local p10k=/usr/local/share/powerlevel10k
  if [[ -d "$p10k/.git" ]]; then
    quiet sudo git -C "$p10k" pull --ff-only && ok "powerlevel10k actualizado" || warn "No se pudo actualizar powerlevel10k"
  else
    quiet sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k" \
      && ok "powerlevel10k en $p10k" || warn "No se pudo clonar powerlevel10k"
  fi

  local sudo_plugin=/usr/share/zsh-sudo/sudo.plugin.zsh
  if [[ -s "$sudo_plugin" ]]; then
    ok "Plugin sudo ya presente"
  else
    quiet sudo mkdir -p "${sudo_plugin%/*}"
    quiet sudo curl -fsSL -o "$sudo_plugin" \
      https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/plugins/sudo/sudo.plugin.zsh \
      && ok "Plugin sudo (Esc Esc añade sudo)" || warn "No se pudo descargar el plugin sudo"
  fi
}

# =============================================================================
#  3. Neovim y NvChad
# =============================================================================
nvim_version() { nvim --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'; }

install_neovim() {
  step "Neovim (mínimo $NVIM_MIN para NvChad)"
  local v; v="$(nvim_version || true)"
  if [[ -n "$v" ]] && ver_ge "$v" "$NVIM_MIN"; then
    ok "Neovim $v"; return
  fi

  # ¿Lo trae apt en versión suficiente?
  local cand; cand="$(apt-cache policy neovim 2>/dev/null | awk '/Candidate:/ {print $2}' | grep -oE '^[0-9]+\.[0-9]+(\.[0-9]+)?' || true)"
  if [[ -n "$cand" ]] && ver_ge "$cand" "$NVIM_MIN"; then
    quiet sudo apt-get install -y neovim && { ok "Neovim $cand desde apt"; return; }
  fi

  info "apt trae ${cand:-ninguna versión}; instalo la última estable oficial en /opt/nvim"
  local tmp; tmp="$(mktemp -d)"
  if curl -fsSL -o "$tmp/nvim.tar.gz" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz; then
    quiet sudo rm -rf /opt/nvim
    quiet sudo mkdir -p /opt/nvim
    quiet sudo tar -xzf "$tmp/nvim.tar.gz" -C /opt/nvim --strip-components=1
    quiet sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    hash -r
    v="$(/usr/local/bin/nvim --version 2>/dev/null | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')"
    [[ -n "$v" ]] && ok "Neovim $v en /opt/nvim" || warn "Neovim descargado pero no arranca"
  else
    warn "No se pudo descargar Neovim; NvChad no funcionará hasta que tengas >= $NVIM_MIN"
  fi
  rm -rf "$tmp"
}

install_nvchad() {
  step "NvChad"
  local cfg="$HOME/.config/nvim"
  if [[ -f "$cfg/lua/chadrc.lua" ]] || grep -rqs "NvChad" "$cfg/lua" 2>/dev/null; then
    ok "NvChad ya instalado"; return
  fi
  if [[ -e "$cfg" ]]; then
    mkdir -p "$BACKUP_DIR/.config"
    mv "$cfg" "$BACKUP_DIR/.config/nvim"
    # también la caché vieja, para que NvChad empiece limpio
    for d in "$HOME/.local/share/nvim" "$HOME/.local/state/nvim" "$HOME/.cache/nvim"; do
      [[ -e "$d" ]] && mkdir -p "$BACKUP_DIR/nvim-data" && mv "$d" "$BACKUP_DIR/nvim-data/"
    done
    info "Tu config de nvim anterior está en $BACKUP_DIR"
  fi
  if quiet git clone --depth=1 https://github.com/NvChad/starter "$cfg"; then
    rm -rf "$cfg/.git"
    ok "NvChad en $cfg (la 1ª vez que abras nvim descargará los plugins)"
  else
    warn "No se pudo clonar NvChad"
  fi
}

# =============================================================================
#  4. Enlazar configs con GNU Stow
# =============================================================================
link_configs() {
  step "Enlazando configs (GNU Stow)"
  command -v stow >/dev/null || die "Falta stow (debería haberse instalado con apt)"

  # Permisos de ejecución de los scripts del repo
  chmod +x "$DOTFILES"/bspwm/.config/bspwm/bspwmrc \
           "$DOTFILES"/bspwm/.config/bspwm/scripts/* \
           "$DOTFILES"/polybar/.config/polybar/launch.sh \
           "$DOTFILES"/polybar/.config/polybar/scripts/* \
           "$DOTFILES"/rofi/.config/rofi/*.sh

  local m f d rel target moved=0
  for m in "${MODULES[@]}"; do
    # 1) Carpetas: si p. ej. ~/.config/bspwm es un enlace a otro sitio (otro rice),
    #    se guarda el ENLACE (no lo que hay dentro, que no es tuyo de este repo)
    while IFS= read -r -d '' d; do
      rel="${d#"$DOTFILES/$m/"}"
      target="$HOME/$rel"
      if [[ -L "$target" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; mv "$target" "$BACKUP_DIR/$rel"; moved=1
      elif [[ -e "$target" && ! -d "$target" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; mv "$target" "$BACKUP_DIR/$rel"; moved=1
      fi
    done < <(find "$DOTFILES/$m" -mindepth 2 -type d -print0 | sort -z)

    # 2) Archivos: si en $HOME hay algo que NO es ya un enlace al repo, se guarda
    while IFS= read -r -d '' f; do
      rel="${f#"$DOTFILES/$m/"}"
      target="$HOME/$rel"
      if [[ -L "$target" ]]; then
        [[ "$(readlink -f "$target")" == "$f" ]] && continue
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; mv "$target" "$BACKUP_DIR/$rel"; moved=1
      elif [[ -e "$target" ]]; then
        mkdir -p "$BACKUP_DIR/$(dirname "$rel")"; mv "$target" "$BACKUP_DIR/$rel"; moved=1
      fi
    done < <(find "$DOTFILES/$m" -type f -print0)

    # 3) Enlazar archivo por archivo (--no-folding: ~/.config/bspwm es carpeta real)
    if quiet stow --dir="$DOTFILES" --target="$HOME" --restow --no-folding "$m"; then
      ok "$m"
    else
      warn "stow falló con '$m' (mira $LOG)"
    fi
  done
  (( moved )) && info "Archivos anteriores guardados en $BACKUP_DIR"

  # Archivo del target: creado por ti, para que root escriba en él sin cambiar el dueño
  mkdir -p "$HOME/.config/bin"
  [[ -e "$HOME/.config/bin/target" ]] || : >"$HOME/.config/bin/target"
  ok "Archivo de target: ~/.config/bin/target"
}

# =============================================================================
#  5. zsh para root y shell por defecto
# =============================================================================
setup_root_and_shell() {
  step "zsh para root y shell por defecto"
  local zsh_bin; zsh_bin="$(command -v zsh)" || { warn "zsh no instalado"; return; }

  # root: copias (no enlaces) para evitar los avisos de compaudit / "insecure directories"
  {
    echo "# Copia de $DOTFILES/zsh/.zshrc instalada por install.sh. Para actualizarla: ./install.sh"
    echo "export TARGET_FILE=\"$HOME/.config/bin/target\"   # mismo target que $USER (Polybar)"
    cat "$DOTFILES/zsh/.zshrc"
  } | quiet sudo tee /root/.zshrc
  quiet sudo install -m 644 -o root -g root "$DOTFILES/zsh/.p10k.zsh" /root/.p10k.zsh
  quiet sudo chown root:root /root/.zshrc
  ok "/root/.zshrc y /root/.p10k.zsh (root se ve con 🔥)"

  # Descargar ya el binario de git de p10k (gitstatusd), para que la 1ª terminal salga limpia
  local gs=/usr/local/share/powerlevel10k/gitstatus/install
  if [[ -x "$gs" ]]; then
    quiet "$gs" && quiet sudo "$gs" && ok "gitstatusd descargado (tú y root)" || warn "No se pudo descargar gitstatusd (lo bajará p10k al abrir la terminal)"
  fi

  local u_shell r_shell
  u_shell="$(getent passwd "$USER" | cut -d: -f7)"
  r_shell="$(getent passwd root | cut -d: -f7)"
  if [[ "$u_shell" != "$zsh_bin" ]]; then
    quiet sudo chsh -s "$zsh_bin" "$USER" && ok "Shell de $USER: zsh (al volver a entrar)" || warn "No se pudo cambiar tu shell"
  else ok "Shell de $USER ya es zsh"; fi
  if [[ "$r_shell" != "$zsh_bin" ]]; then
    quiet sudo chsh -s "$zsh_bin" root && ok "Shell de root: zsh" || warn "No se pudo cambiar la shell de root"
  else ok "Shell de root ya es zsh"; fi
}

# =============================================================================
#  6. Sesión bspwm en la pantalla de login
# =============================================================================
setup_session() {
  step "Sesión bspwm en el login"
  local dst=/usr/share/xsessions/bspwm.desktop
  if [[ -f "$dst" ]]; then
    ok "Ya existe $dst"
  else
    quiet sudo mkdir -p /usr/share/xsessions
    printf '%s\n' "[Desktop Entry]" "Name=bspwm" "Comment=Binary space partitioning window manager" \
                  "Exec=bspwm" "Type=Application" | quiet sudo tee "$dst"
    ok "Creado $dst"
  fi

  # Aviso si hay dos bspwm (uno compilado en /usr/local y otro de apt)
  if [[ -x /usr/local/bin/bspwm && -x /usr/bin/bspwm ]]; then
    warn "Tienes bspwm dos veces (/usr/local/bin compilado y /usr/bin de apt). Se usará el de /usr/local. Para quitar el compilado: cd ~/bspwm && sudo make uninstall"
  fi
}

# =============================================================================
#  7. Comprobación final
# =============================================================================
verify() {
  step "Comprobación final"
  local bin
  for bin in bspwm bspc sxhkd kitty polybar picom rofi dunst feh xdotool xclip wmname zsh lsd batcat nvim stow i3lock-fancy flameshot; do
    if command -v "$bin" >/dev/null; then ok "$bin"; else warn "Falta el comando: $bin"; fi
  done

  sh -n "$HOME/.config/bspwm/bspwmrc" && ok "bspwmrc: sintaxis correcta" || warn "bspwmrc tiene errores"
  zsh -n "$HOME/.zshrc"               && ok ".zshrc: sintaxis correcta"   || warn ".zshrc tiene errores"
  [[ -L "$HOME/.config/sxhkd/sxhkdrc" ]] && ok "Configs enlazadas al repo" || warn "Las configs no están enlazadas"
  has_font && ok "Hack Nerd Font" || warn "Falta Hack Nerd Font"
  local v; v="$(nvim_version || true)"
  [[ -n "$v" ]] && ver_ge "$v" "$NVIM_MIN" && ok "Neovim $v" || warn "Neovim < $NVIM_MIN"
}

summary() {
  printf '\n%s════════════════════════════════════════════════════════════%s\n' "$B" "$N"
  if (( ${#WARNINGS[@]} )); then
    printf '%s Terminado con %d aviso(s):%s\n' "$Y" "${#WARNINGS[@]}" "$N"
    printf '   - %s\n' "${WARNINGS[@]}"
  else
    printf '%s Todo instalado sin avisos.%s\n' "$G" "$N"
  fi
  cat <<EOF

  Siguiente:
    1. Cierra sesión y en el login elige ${BOLD}bspwm${N}
    2. super + Return  → terminal   ·   super + d → apps
    3. Abre ${BOLD}nvim${N} una vez y espera a que instale los plugins

  Registro completo:  $LOG
EOF
  [[ -d "$BACKUP_DIR" ]] && echo "  Copias de seguridad: $BACKUP_DIR"
  printf '%s════════════════════════════════════════════════════════════%s\n\n' "$B" "$N"
}

# =============================================================================
main() {
  printf '\n%s  dotfiles · phant0m%s  (bspwm · zsh · nvim)\n' "$BOLD" "$N"
  check_system
  confirm
  install_packages
  install_font
  install_p10k
  install_neovim
  install_nvchad
  link_configs
  setup_root_and_shell
  setup_session
  verify
  summary
}

main
