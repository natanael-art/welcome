#!/usr/bin/env bash

XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}";
cd "${XDG_CONFIG_HOME}";

COLOR_MODE=$((plasma-apply-colorscheme -l | grep -q '^*.*Dark') && echo "Dark" || echo "Light")
ACCENT_COLOR=$((kreadconfig6 --file kdeglobals --group General --key AccentColor 2>/dev/null || echo "#3daee9") | tr '[:upper:]' '[:lower:]');

declare -A applications_name=(
    [com.google.Chrome]="Google Chrome"
    [com.microsoft.Edge]="Microsoft Edge"
    [com.brave.Browser]="Brave"
    [io.gitlab.librewolf-community]="LibreWolf"
    [com.opera.opera-gx]="Opera GX"
    [org.torproject.torbrowser-launcher]="Tor Browser"
    
    [org.libreoffice.LibreOffice]="LibreOffice"
    [com.wps.Office]="WPS Office"
    [webapp.gdocs]="Google Docs"
    [webapp.office365]="Office 365 Online"
)

set -euo pipefail

LAYOUTS="/usr/share/mainuan/layouts"

die()      { log "ERRO: $*" >&2; exit 1; }

kcm() {
    kcmshell6 "$1" &
}

url() {
    [[ "$1" == *t.me* ]] && command -v telegram-desktop &>/dev/null \
        && { telegram-desktop -- "$1" & return; }
    xdg-open "$1" &
}

terminal() {
    konsole --hide-menubar --hide-toolbar --hold -e bash -c "$1" &
}

install() {
    flatpak-install-gui --override-appname="${applications_name[$1]}" $1
}

remove() {
    flatpak-install-gui --override-appname="${applications_name[$1]}" --remove $1
}

layout() {
    local f="$LAYOUTS/$1.js"
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
                echo -n "${COLOR_MODE}" | tr '[:upper:]' '[:lower:]';;

    --get-color)
                echo -n "${ACCENT_COLOR}" | tr '[:upper:]' '[:lower:]';;

    accent)
                plasma-apply-colorscheme --accent-color "$2"
                plasma-apply-colorscheme --accent-color "$2"
                kwriteconfig6 --file kdeglobals --group General --key AccentColor "$2"
                ;;

    theme)      
                kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key library org.kde.kwin.aurorae
                case "$2" in
                    dark)  
                        plasma-apply-colorscheme DreamGrayDarkColor 
                        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Grey-Dark
                        ;;
                    light) 
                        plasma-apply-colorscheme DreamGrayLightColor 
                        kwriteconfig6 --file kwinrc --group org.kde.kdecoration2 --key theme Grey-Light
                        ;;
                esac
                kwriteconfig6 --file kdeglobals --group General --key AccentColor "$2"
                qdbus6 org.kde.KWin /KWin reconfigure 2>/dev/null || true 
                ;;

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
