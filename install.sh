#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset
IFS=$'\n\t'

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

print_error()   { printf "\e[01;31m[✗] %s\e[0m\n" "$@" >&2; }
print_warn()    { printf "\e[01;33m[!] %s\e[0m\n" "$@" >&2; }
print_info()    { printf "\e[01;34m[i] %s\e[0m\n" "$@"; }
print_okay()    { printf "\e[01;32m[✓] %s\e[0m\n" "$@"; }
print_action()  { printf "\e[01;37m[~] %s\e[0m\n" "$@"; }
print_text()    { printf "%s\n" "$@"; }
print_clear()   { printf '\033[1A\033[2K'; }

main() {
    local -r default_user="$(id --user --name 1000)"

    # --------------------------------------------------
    if [[ $EUID -ne 0 ]]; then
        print_error "Script needs root user privileges"
        return 1
    fi

    # --------------------------------------------------
    # if [[ $# -eq 0 ]]; then
    #     print_error "No arguments provided; use --help for further information"
    #     return 1
    # fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                print_text "Usage: $SCRIPT_NAME [OPTIONS]"
                print_text ""
                print_text "Options:"
                print_text "  -h, --help            Show this help message and exit"
                return 0
                ;;
            -*|--*)
                print_error "Unknown option: $1; use --help for further information"
                return 1
                ;;
            *)
                print_error "Unexpected argument: $1; use --help for further information"
                return 1
                ;;
        esac
        shift
    done

    # --------------------------------------------------
    print_action "Upgrading packages ..."
    apt update || {
        print_error "Failed to update sources"
        return 1
    }

    # --------------------------------------------------
    print_action "Installing live-build ..."
    apt install \
        live-build \
        isolinux || {
        print_error "Failed to install packages"
        return 1
    }

    # --------------------------------------------------
    print_action "Installing apt-cacher-ng ..."
    apt install \
        apt-cacher-ng || {
        print_error "Failed to install packages"
        return 1
    }

    local apt_cacher_conf="/etc/apt/apt.conf.d/90proxy"
    echo 'Acquire::http::Proxy "http://localhost:3142";' \
    | tee "$apt_cacher_conf" && \
    echo 'Acquire::https::Proxy "http://localhost:3142";' \
    | tee --append "$apt_cacher_conf" || {
        print_warn "Failed to update proxy configuration"
    }

    systemctl enable --now apt-cacher-ng.service || {
        print_error "Failed to start service"
        return 1
    }

    # --------------------------------------------------
    print_action "Installing qemu ..."
    apt install \
        qemu-system-x86 || {
        print_error "Failed to install packages"
        return 1
    }

    # --------------------------------------------------
    # --------------------------------------------------
    print_action "Cleaning up system ..."
    apt autoremove --purge || {
        print_error "Failed to autoremove dependencies"
        return 1
    }

    apt clean || {
        print_error "Failed to clean up package cache"
        return 1
    }

    # --------------------------------------------------
    print_okay "Installation finished successfully"
    print_text "Reboot required to apply all changes"
    return 0
}

main "$@"
exit $?
