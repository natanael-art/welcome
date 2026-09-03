#!/usr/bin/env bash
# /usr/bin/welcome-cli.sh — Mainuan OS · Welcome App CLI

set -euo pipefail

LOG="/tmp/mainuan-welcome.log"
LAYOUTS="/usr/share/mainuan/layouts"

log()      { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }
die()      { log "ERRO: $*" >&2; exit 1; }

kcm() {
    log "KCM: $1"
    kcmshell6 "$1" &
}

url() {
    log "URL: $1"
    [[ "$1" == *t.me* ]] && command -v telegram-desktop &>/dev/null \
        && { telegram-desktop -- "$1" & return; }
    xdg-open "$1" &
}

terminal() {
    konsole --hide-menubar --hide-toolbar --hold -e bash -c "$1" &
}

install() {
    log "Instalando: $1"
    pkexec bash -c "
        : # ← implementar aqui
        # apt install -y '$1'
    " && mkdir -p "$" && touch "$CAPPS/$1"
}

remove() {
    log "Removendo: $1"
    pkexec bash -c "apt remove -y '$1' && apt autoremove -y" \
        && rm -f "$CAPPS/$1"
}

layout() {
    local f="$LAYOUTS/$1.js"
    log "Layout: $1"
    [[ -f "$f" ]] \
        && qdbus6 org.kde.plasmashell /PlasmaShell \
               org.kde.PlasmaShell.loadLayout "$f" 2>/dev/null \
        || kwriteconfig6 --file plasmashellrc \
               --group PlasmaViews --key layout "$1"
    qdbus6 org.kde.plasmashell /PlasmaShell \
        org.kde.PlasmaShell.refreshCurrentShell 2>/dev/null || true
}


# ── Dispatcher ────────────────────────────────────────────────────────────────


case "${1:-}" in

    --get-theme)
                (plasma-apply-colorscheme -l | grep -q '^*.*Dark') && echo "dark" || echo "light" ;;

    --get-color)
                kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null || echo "" ;;

    accent)     log "Cor de destaque: $2"
                plasma-apply-colorscheme --accent-color "$2" && \
                plasma-apply-colorscheme --accent-color "$2" && \
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true ;;

    theme)      log "Tema: $2"
                case "$2" in
                    dark)  plasma-apply-colorscheme BreezeDark  ;;
                    light) plasma-apply-colorscheme BreezeLight ;;
                esac
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true ;;

    antivirus)  terminal "
                    echo '=== Mainuan — Antivírus (ClamAV) ==='
                    sudo apt install -y clamav clamav-daemon
                    sudo freshclam
                    echo '=== Instalado e atualizado ==='
                    read -p 'Enter para fechar...'
                " ;;

    firewall)   kcm kcm_firewall;;

    codecs)     terminal "
                    echo '=== Mainuan — Codecs de Mídia ==='
                    sudo apt install -y ubuntu-restricted-extras ffmpeg gstreamer1.0-plugins-bad
                    echo '=== Instalado ==='
                    read -p 'Enter para fechar...'
                " ;;

    drivers)    kubuntu-driver-manager ;;

    install)    install "$2" ;;
    remove)     remove  "$2" ;;

    layout)     case "$2" in
                    latte-unity)
                        kwriteconfig6 --file lattedockrc \
                            --group UniversalSettings --key currentLayout Unity
                        latte-dock --layout Unity & ;;
                    tiling)
                        kwriteconfig6 --file kwinrc \
                            --group Plugins --key bismuthEnabled true
                        qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true ;;
                    *)  layout "$2" ;;
                esac ;;

    github)     url "https://github.com/mainuanos/mainuan" ;;
    report)     url "https://github.com/mainuanos/mainuan/issues/new" ;;
    telegram)   url "https://t.me/mainuanos" ;;

    *)          echo "Uso: $(basename "$0") <accent <#hex>|theme <dark|light>|antivirus|firewall|codecs|drivers|install <pkg>|remove <pkg>|layout <id>|github|report|telegram>"
                exit 1 ;;
esac
