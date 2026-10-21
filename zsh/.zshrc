# ~/.zshrc  ·  phant0m
# Comprobar sintaxis tras cada cambio: zsh -n ~/.zshrc

#==================== POWERLEVEL10K: ARRANQUE RÁPIDO ====================
# Debe ir arriba del todo. Si el archivo de caché no existe, no hace nada.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

#==================== PATH ====================
export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
typeset -U PATH path            # quita rutas repetidas

#==================== HISTORIAL ====================
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt histignorealldups sharehistory

#==================== AUTOCOMPLETADO ====================
autoload -Uz compinit
compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/zcompdump-$ZSH_VERSION"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # sin distinguir mayúsculas

#==================== TECLAS ====================
bindkey -e                                   # modo emacs (Ctrl+A, Ctrl+E…)
bindkey '^[[H'    beginning-of-line          # Inicio
bindkey '^[[F'    end-of-line                # Fin
bindkey '^[[3~'   delete-char                # Supr
bindkey '^[[1;5C' forward-word               # Ctrl + →
bindkey '^[[1;5D' backward-word              # Ctrl + ←

#==================== ALIAS ====================
# lsd (ls con iconos)
alias ls='lsd --group-dirs=first'
alias ll='lsd -lh --group-dirs=first'
alias la='lsd -lha --group-dirs=first'
alias l='lsd -lah --group-dirs=first'
alias lt='lsd --tree --depth=2'

# batcat (cat con colores; en Debian/Parrot el comando se llama batcat)
alias cat='batcat'
alias catn='/usr/bin/cat'                         # el cat de siempre
alias catnp='batcat --style=plain --paging=never' # bonito pero sin paginar

# nvim
alias vim='nvim'
alias v='nvim'
export EDITOR=nvim VISUAL=nvim

# fzf: Ctrl+R busca en el historial, Ctrl+T busca archivos
[[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]] && source /usr/share/doc/fzf/examples/key-bindings.zsh

#==================== FUNCIONES DE PENTESTING ====================

# mkt: crea las carpetas de trabajo de una máquina
mkt() {
  mkdir -p {nmap,content,exploits}
  echo "[+] Creadas: nmap/ content/ exploits/"
}

# extractPorts: lee un escaneo de nmap en formato -oG y copia los puertos al portapapeles
# uso: extractPorts allPorts
extractPorts() {
  if [[ ! -f "$1" ]]; then
    echo "[!] Uso: extractPorts <archivo_nmap_-oG>"; return 1
  fi
  local ports ip
  ports="$(grep -oP '\d{1,5}/open' "$1" | awk -F/ '{print $1}' | xargs | tr ' ' ',')"
  ip="$(grep -oP '^Host: \K[^ ]+' "$1" | sort -u | head -n 1)"
  echo "[*] IP:      $ip"
  echo "[*] Puertos: $ports"
  printf '%s' "$ports" | xclip -selection clipboard && echo "[+] Puertos copiados al portapapeles"
}

# settarget / cleartarget: la máquina víctima que muestra Polybar
# TARGET_FILE apunta al archivo de tu usuario (root también escribe ahí; lo fija install.sh)
: ${TARGET_FILE:=$HOME/.config/bin/target}

settarget() {
  if [[ $# -lt 1 ]]; then
    echo "[!] Uso: settarget <IP> [nombre]"; return 1
  fi
  [[ -e "$TARGET_FILE" ]] || mkdir -p "${TARGET_FILE:h}"
  printf '%s\n' "$*" > "$TARGET_FILE"     # al sobrescribir, el dueño del archivo no cambia
  echo "[+] Target: $*"
}

cleartarget() {
  [[ -e "$TARGET_FILE" ]] || mkdir -p "${TARGET_FILE:h}"
  : > "$TARGET_FILE"                      # lo deja vacío, sin borrarlo
  echo "[+] Target borrado"
}

#==================== PLUGINS ====================
# Orden: autosuggestions → sudo → syntax-highlighting (este siempre el último)
[[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh

[[ -f /usr/share/zsh-sudo/sudo.plugin.zsh ]] && \
  source /usr/share/zsh-sudo/sudo.plugin.zsh            # Esc dos veces: añade sudo

[[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#==================== POWERLEVEL10K ====================
[[ -f /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme ]] && \
  source /usr/local/share/powerlevel10k/powerlevel10k.zsh-theme

# Tu configuración del prompt (la crea: p10k configure)
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh
