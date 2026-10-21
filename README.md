# dotfiles · phant0m

Entorno de trabajo para **Parrot OS** y **Kali Linux**: bspwm + sxhkd, Polybar con IP/VPN/target,
picom, Rofi, Kitty, zsh con powerlevel10k, lsd, batcat y Neovim con NvChad. Colores Tokyo Night
y Hack Nerd Font.

```
 1 2 3 4 5 6 7 8 9 10          󰓾 10.10.11.42 Pandora          󰆧 10.10.14.7 | 󰩟 192.168.1.50 | 󰻠 3% | 󰍛 0.8 GiB | 󰥔 20/10 21:54 | ⏻
```

---

## Instalación

```bash
git clone https://github.com/Chenchi979/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

- Ejecútalo **como tu usuario**, no con `sudo` (te pedirá la contraseña una vez).
- Al terminar: cierra sesión y elige **bspwm** en la pantalla de login.
- Abre `nvim` una vez y espera a que descargue los plugins.

`./install.sh` se puede repetir siempre que quieras: lo que ya está instalado lo deja, y lo que
pisa lo guarda antes en `~/.dotfiles-backup/<fecha>/`. Todo queda registrado en
`~/.dotfiles-install.log`.

### Qué hace

| Paso | Detalle |
|---|---|
| Paquetes | Los de `packages/apt.txt`. Si alguno no existe en tu versión, avisa y sigue. En VMware añade `open-vm-tools-desktop`. |
| Fuente | Hack Nerd Font en `~/.local/share/fonts` |
| zsh | powerlevel10k en `/usr/local/share/powerlevel10k`, plugin `sudo`, autosuggestions, syntax-highlighting |
| Neovim | Si apt trae una versión menor que 0.10, instala la oficial en `/opt/nvim` |
| NvChad | En `~/.config/nvim` (tu config anterior va a la copia de seguridad) |
| Configs | Enlaces simbólicos con GNU Stow: `~/.config/...` → `~/dotfiles/...` |
| root | Copia de `.zshrc` y `.p10k.zsh` en `/root` (root sale con 🔥) |
| Shell | zsh por defecto para ti y para root |
| Login | Crea `/usr/share/xsessions/bspwm.desktop` si no existe |

---

## Estructura

Cada carpeta es un **módulo de Stow**: dentro tiene la misma ruta que en tu `$HOME`.

```
dotfiles/
├── install.sh
├── packages/apt.txt
├── bspwm/.config/bspwm/
│   ├── bspwmrc
│   └── scripts/{bspw_resize, scratchpad}
├── sxhkd/.config/sxhkd/sxhkdrc
├── kitty/.config/kitty/kitty.conf
├── picom/.config/picom/picom.conf
├── polybar/.config/polybar/
│   ├── config.ini
│   ├── launch.sh
│   └── scripts/{ip.sh, vpn.sh, target.sh}
├── rofi/.config/rofi/{config.rasi, tokyonight.rasi, powermenu.sh}
├── dunst/.config/dunst/dunstrc
└── zsh/{.zshrc, .p10k.zsh}
```

Como `~/.config/sxhkd/sxhkdrc` es un enlace al repo, **al editar uno editas el otro**.
Para guardar un cambio:

```bash
cd ~/dotfiles
git add -A && git commit -m "sxhkd: nuevo atajo" && git push
```

Y en otra máquina: `cd ~/dotfiles && git pull`.

---

## Atajos (sxhkd)

`super` = tecla Windows. Recargar atajos: `super + Escape`. Recargar bspwm: `super + alt + r`.

### Programas
| Atajo | Acción |
|---|---|
| `super + Return` | Kitty |
| `super + z` | Terminal flotante (scratchpad): aparece / se esconde |
| `super + d` | Rofi: lanzador de apps |
| `super + shift + d` | Rofi: cambiar de ventana |
| `super + shift + f` | Firefox |
| `super + shift + b` | Burp Suite (se abre en el escritorio 3) |
| `Print` | Captura con Flameshot |
| `super + l` | Bloquear pantalla (i3lock-fancy) |
| `super + shift + e` | Menú: bloquear / cerrar sesión / reiniciar / apagar |

### Ventanas
| Atajo | Acción |
|---|---|
| `super + q` | Cerrar ventana |
| `super + shift + q` | Matar el programa |
| `super + t` / `super + shift + t` | Mosaico / pseudo-mosaico |
| `super + s` | Flotante |
| `super + f` | Pantalla completa |
| `super + m` | Alternar mosaico ↔ monocle (una ventana ocupa el escritorio) |
| `super + g` | Cambiar la ventana por la más grande |

### Mover y redimensionar
| Atajo | Acción |
|---|---|
| `super + flechas` | Mover el foco |
| `super + shift + flechas` | Intercambiar con la ventana de al lado |
| `super + ctrl + flechas` | Mover una ventana flotante |
| `super + alt + flechas` | Redimensionar (`bspw_resize`: 100 px; 20 px si es flotante) |
| `super + 1…0` | Ir al escritorio 1…10 |
| `super + shift + 1…0` | Mandar la ventana al escritorio 1…10 |
| `super + Tab` | Volver al último escritorio |

### Preselección (elegir dónde se abre la próxima ventana)
| Atajo | Acción |
|---|---|
| `ctrl + super + alt + flechas` | Preseleccionar ese lado |
| `ctrl + super + alt + 1…9` | Qué parte ocupará (10 %…90 %) |
| `ctrl + super + alt + space` | Cancelar |
| `ctrl + super + alt + q` | Salir de bspwm |

### Ratón
| Atajo | Acción |
|---|---|
| `super + clic izquierdo` | Mover ventana |
| `super + clic derecho` | Redimensionar desde la esquina |

### Kitty
| Atajo | Acción |
|---|---|
| `ctrl + shift + t` / `w` | Nueva pestaña / cerrarla |
| `ctrl + shift + alt + t` | Renombrar pestaña |
| `ctrl + shift + ← →` | Cambiar de pestaña |
| `ctrl + shift + Return` | Dividir la ventana |
| `ctrl + shift + z` | Ampliar la división actual |

---

## Polybar

| Módulo | Qué muestra | Clic |
|---|---|---|
| Escritorios | 1–10 (azul: actual, morado: con ventanas) | Cambia de escritorio |
| Target | Lo que pongas con `settarget` | — |
| VPN | IP de `tun0` (HTB, THM) o `VPN off` | Copia la IP |
| IP | Tu IP local | Copia la IP |
| CPU / RAM / Hora | — | — |
| ⏻ | — | Menú de apagado |

## zsh

| Comando | Qué hace |
|---|---|
| `settarget 10.10.11.42 Pandora` | Pone el target en Polybar (también desde root) |
| `cleartarget` | Lo borra (el archivo queda vacío) |
| `mkt` | Crea `nmap/ content/ exploits/` |
| `extractPorts allPorts` | Lee un `nmap -oG` y copia los puertos al portapapeles |
| `ls`, `ll`, `la`, `lt` | lsd con iconos (`lt` = árbol) |
| `cat` | batcat con colores · `catn` = cat normal · `catnp` = batcat sin paginar |
| `v`, `vim` | nvim |
| `Esc Esc` | Añade `sudo` delante del comando |
| `Ctrl + R` / `Ctrl + T` | fzf: buscar en el historial / buscar archivos |

**Prompt** (todo a la izquierda): logo · usuario@máquina · carpeta · rama git · ✔/✘ código ·
hora · ❯. Root sale en naranja con 🔥. Se cambia en `zsh/.p10k.zsh`
(`POWERLEVEL9K_LEFT_PROMPT_ELEMENTS`).

---

## Personalizar

| Quiero… | Dónde |
|---|---|
| Fondo de pantalla | Copia tu imagen a `~/.config/wallpaper.jpg` (o `.png`) y `super + alt + r` |
| Gaps, bordes, colores | `bspwm/.config/bspwm/bspwmrc` |
| Que un programa se abra en un escritorio o flotante | `bspc rule` en `bspwmrc`. El nombre: `xprop \| grep WM_CLASS` y clic en la ventana |
| Módulos de Polybar | `modules-left / center / right` en `config.ini` |
| Transparencia de Kitty | `background_opacity` en `kitty.conf` |
| Añadir un paquete | Una línea en `packages/apt.txt` y `./install.sh` |

---

## Problemas típicos

**No aparece bspwm en el login** → `ls /usr/share/xsessions/`. Si falta `bspwm.desktop`, vuelve
a ejecutar `./install.sh`.

**Ventanas negras o Kitty no abre (VMware)** → la VM no tiene aceleración 3D. `bspwmrc` lo
detecta solo y usa `picom --backend xrender` y render por software. Para ir más fluido: apaga la
VM → *Settings → Display → Accelerate 3D graphics*.

**`ctrl + super + alt + …` me saca de la VM** → `Ctrl + Alt` es el atajo de VMware para soltar
el ratón. Cámbialo en VMware: *Edit → Preferences → Hotkeys*.

**Un atajo no hace nada dentro de la VM** → puede que lo esté capturando el bspwm/sxhkd de tu
máquina anfitriona (Arch). Prueba con la VM en pantalla completa.

**Los iconos salen como cuadrados** → falta la fuente: `fc-list | grep "Hack Nerd"`.

**Dos bspwm** (uno compilado en `/usr/local` y otro de apt) → el instalador avisa. Para quitar
el compilado: `cd ~/bspwm && sudo make uninstall`.

**Deshacer todo** →
```bash
cd ~/dotfiles && stow -D -t ~ bspwm sxhkd kitty picom polybar rofi dunst zsh
cp -a ~/.dotfiles-backup/<fecha>/. ~/
```
