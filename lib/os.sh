#!/usr/bin/env bash

detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$ID
        OS_VERSION=$VERSION_ID
    elif [ -f /etc/synoinfo.conf ]; then
        OS_NAME="synology"
        OS_VERSION="dsm"
    elif [ -f /etc/alpine-release ]; then
        OS_NAME="alpine"
    else
        OS_NAME=$(uname -s | tr '[:upper:]' '[:lower:]')
    fi
}

detect_os

case "$OS_NAME" in
    ubuntu|debian|pop|linuxmint|kali|raspbian)
        PKG_MANAGER="apt"
        PKG_UPDATE="apt update"
        PKG_INSTALL="apt install -y"
        PKG_REMOVE="apt remove -y"
        PKG_CHECK="dpkg -l"
        SUDO_CMD="sudo"
        ;;
    fedora|rhel|centos|almalinux|rocky)
        PKG_MANAGER="dnf"
        PKG_UPDATE="dnf check-update"
        PKG_INSTALL="dnf install -y"
        PKG_REMOVE="dnf remove -y"
        PKG_CHECK="rpm -qa"
        SUDO_CMD="sudo"
        ;;
    arch|manjaro|endeavouros)
        PKG_MANAGER="pacman"
        PKG_UPDATE="pacman -Sy"
        PKG_INSTALL="pacman -S --noconfirm"
        PKG_REMOVE="pacman -Rns --noconfirm"
        PKG_CHECK="pacman -Q"
        SUDO_CMD="sudo"
        ;;
    alpine)
        PKG_MANAGER="apk"
        PKG_UPDATE="apk update"
        PKG_INSTALL="apk add"
        PKG_REMOVE="apk del"
        PKG_CHECK="apk info -e"
        SUDO_CMD="sudo"
        if [ "$EUID" -eq 0 ]; then
            SUDO_CMD=""
        fi
        ;;
    synology)
        PKG_MANAGER="synogear"
        PKG_UPDATE=""
        PKG_INSTALL="synogear install"
        PKG_REMOVE=""
        SUDO_CMD="sudo"
        ;;
    *)
        PKG_MANAGER="unknown"
        PKG_UPDATE=""
        PKG_INSTALL=""
        PKG_REMOVE=""
        SUDO_CMD=""
        ;;
esac

run_sudo() {
    if [ "$EUID" -eq 0 ]; then
        "$@"
    else
        $SUDO_CMD "$@"
    fi
}

pkg_update() {
    [ -z "$PKG_UPDATE" ] && return 0
    log_info "Updating package lists ($PKG_MANAGER)..."
    if run_sudo $PKG_UPDATE >/dev/null 2>&1; then
        return 0
    else
        log_warning "Package update failed"
        return 1
    fi
}

pkg_is_installed() {
    local pkg="$1"
    case "$PKG_MANAGER" in
        apt)
            dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"
            ;;
        dnf)
            rpm -q "$pkg" >/dev/null 2>&1
            ;;
        pacman)
            pacman -Q "$pkg" >/dev/null 2>&1
            ;;
        apk)
            apk info -e "$pkg" >/dev/null 2>&1
            ;;
        *)
            command -v "$pkg" >/dev/null 2>&1
            ;;
    esac
}

pkg_install() {
    [ -z "$PKG_INSTALL" ] && return 1
    
    local to_install=()
    for pkg in "$@"; do
        if ! pkg_is_installed "$pkg"; then
            to_install+=("$pkg")
        fi
    done
    
    if [ ${#to_install[@]} -eq 0 ]; then
        return 0
    fi
    
    log_info "Installing: ${to_install[*]} ($PKG_MANAGER)..."
    if run_sudo $PKG_INSTALL "${to_install[@]}"; then
        return 0
    else
        log_error "Failed to install: ${to_install[*]}"
        return 1
    fi
}

pkg_remove() {
    [ -z "$PKG_REMOVE" ] && return 1
    log_info "Removing: $* ($PKG_MANAGER)..."
    run_sudo $PKG_REMOVE "$@"
}
