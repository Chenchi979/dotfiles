# ~/.p10k.zsh  ·  phant0m
# Prompt a la izquierda; nada a la derecha.
# Tras cambiar algo: exec zsh   (o abre otra terminal)
# Lista de segmentos posibles: https://github.com/romkatv/powerlevel10k#batteries-included

'builtin' 'local' '-a' 'p10k_config_opts'
[[ ! -o 'aliases'         ]] || p10k_config_opts+=('aliases')
[[ ! -o 'sh_glob'         ]] || p10k_config_opts+=('sh_glob')
[[ ! -o 'no_brace_expand' ]] || p10k_config_opts+=('no_brace_expand')
'builtin' 'setopt' 'no_aliases' 'no_sh_glob' 'brace_expand'

() {
  emulate -L zsh -o extended_glob
  unset -m '(POWERLEVEL9K_*|DEFAULT_USER)~POWERLEVEL9K_GITSTATUS_DIR'

  #==================== QUÉ SE VE ====================
  # Quita o reordena elementos de esta lista a tu gusto
  typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
    os_icon        # logo de la distro (Parrot / Kali)
    context        # usuario@máquina  (root lleva 🔥)
    dir            # carpeta actual
    vcs            # rama de git, si estás en un repo
    status         # ✔ o ✘ con el código de error del último comando
    time           # hora
    prompt_char    # ❯ (verde si fue bien, rojo si falló)
  )
  typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=()

  #==================== ESTILO GENERAL ====================
  typeset -g POWERLEVEL9K_MODE=nerdfont-complete
  typeset -g POWERLEVEL9K_ICON_PADDING=none
  typeset -g POWERLEVEL9K_BACKGROUND=                       # sin fondos: estilo limpio
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_{LEFT,RIGHT}_WHITESPACE=
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SUBSEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_{LEFT,RIGHT}_SEGMENT_SEPARATOR=
  typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR=' '
  typeset -g POWERLEVEL9K_VISUAL_IDENTIFIER_EXPANSION='${P9K_VISUAL_IDENTIFIER}'
  typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE=true           # línea en blanco entre comandos
  typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
  typeset -g POWERLEVEL9K_TRANSIENT_PROMPT=off
  typeset -g POWERLEVEL9K_DISABLE_HOT_RELOAD=true

  #==================== LOGO ====================
  typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=39

  #==================== USUARIO@MÁQUINA ====================
  typeset -g POWERLEVEL9K_CONTEXT_FOREGROUND=111
  typeset -g POWERLEVEL9K_CONTEXT_TEMPLATE='%n@%m'
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_FOREGROUND=208
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_TEMPLATE='%B%n@%m%b'
  typeset -g POWERLEVEL9K_CONTEXT_ROOT_VISUAL_IDENTIFIER_EXPANSION='🔥'
  # se ve siempre (también en local, no solo por SSH)
  typeset -g POWERLEVEL9K_CONTEXT_{DEFAULT,SUDO}_CONTENT_EXPANSION='%n@%m'

  #==================== CARPETA ====================
  typeset -g POWERLEVEL9K_DIR_FOREGROUND=147
  typeset -g POWERLEVEL9K_DIR_ANCHOR_FOREGROUND=111
  typeset -g POWERLEVEL9K_DIR_ANCHOR_BOLD=true
  typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique
  typeset -g POWERLEVEL9K_DIR_MAX_LENGTH=60
  typeset -g POWERLEVEL9K_DIR_HOME_VISUAL_IDENTIFIER_EXPANSION='󰋜'           # casa
  typeset -g POWERLEVEL9K_DIR_HOME_SUBFOLDER_VISUAL_IDENTIFIER_EXPANSION='󰝰'
  typeset -g POWERLEVEL9K_DIR_DEFAULT_VISUAL_IDENTIFIER_EXPANSION='󰉋'
  typeset -g POWERLEVEL9K_DIR_ETC_VISUAL_IDENTIFIER_EXPANSION='󰒓'

  #==================== GIT ====================
  typeset -g POWERLEVEL9K_VCS_FOREGROUND=150
  typeset -g POWERLEVEL9K_VCS_BRANCH_ICON='󰘬 '

  #==================== ESTADO DEL ÚLTIMO COMANDO ====================
  typeset -g POWERLEVEL9K_STATUS_EXTENDED_STATES=true
  typeset -g POWERLEVEL9K_STATUS_OK=true
  typeset -g POWERLEVEL9K_STATUS_OK_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_FOREGROUND=70
  typeset -g POWERLEVEL9K_STATUS_OK_PIPE_VISUAL_IDENTIFIER_EXPANSION='✔'
  typeset -g POWERLEVEL9K_STATUS_ERROR=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_VERBOSE_SIGNAME=false
  typeset -g POWERLEVEL9K_STATUS_ERROR_SIGNAL_VISUAL_IDENTIFIER_EXPANSION='✘'
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE=true
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_FOREGROUND=160
  typeset -g POWERLEVEL9K_STATUS_ERROR_PIPE_VISUAL_IDENTIFIER_EXPANSION='✘'

  #==================== HORA ====================
  typeset -g POWERLEVEL9K_TIME_FOREGROUND=243
  typeset -g POWERLEVEL9K_TIME_FORMAT='%D{%H:%M:%S}'
  typeset -g POWERLEVEL9K_TIME_UPDATE_ON_COMMAND=false
  typeset -g POWERLEVEL9K_TIME_VISUAL_IDENTIFIER_EXPANSION='󰅐'

  #==================== ❯ ====================
  typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=76
  typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=196
  typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='❯'
  typeset -g POWERLEVEL9K_PROMPT_CHAR_LEFT_PROMPT_LAST_SEGMENT_END_SYMBOL=''

  (( ! $+functions[p10k] )) || p10k reload
}

typeset -g POWERLEVEL9K_CONFIG_FILE=${${(%):-%x}:a}
(( ${#p10k_config_opts} )) && setopt ${p10k_config_opts[@]}
'builtin' 'unset' 'p10k_config_opts'
