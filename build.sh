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
    elif ! command -v lb >/dev/null 2>&1; then
        print_error "Required package not installed: live-build"
        return 1
    fi
    local config_dir="$SCRIPT_DIR/config"
    if ! [[ -d "$config_dir" ]]; then
        print_error "Configuration directory not found: $config_dir"
        return 1
    fi

    # --------------------------------------------------
    # if [[ $# -eq 0 ]]; then
    #     print_error "No arguments provided; use --help for further information"
    #     return 1
    # fi
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --debug)
                local compression='lz4'
                break
                ;;
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
    print_action "Create live build environment ..."
    local build_name="live-build-$(date +%Y%m%d-%H%M%S)"
    local build_dir="$SCRIPT_DIR/$build_name"
    mkdir --parents "$build_dir" || {
        print_error "Failed to create build directory"
        return 1
    }

    cd "$build_dir" || {
        print_error "Failed to change to build directory"
        return 1
    }

    # --------------------------------------------------
    print_action "Creating build configuration ..."
    local -r locales='locales=de_DE.UTF-8 keyboard-layouts=de timezone=Europe/Berlin'
    local -r hostname='hostname=eua-schleuse'
    local -r username='username=debian'
    local -r tmpfs="toram toram=filesystem.squashfs"
    lb config noauto \
        --architectures "amd64" \
        --distribution "trixie" \
        --debian-installer "none" \
        --archive-areas "main contrib non-free non-free-firmware" \
        --bootappend-live "boot=live components $locales $hostname $username $tmpfs" \
        --debootstrap-options "--variant=minbase" \
        --chroot-squashfs-compression-type "${compression:-xz}" \
        --binary-images "iso-hybrid" \
        --memtest "none" || {
        print_error "Failed to initialize configuration"
        return 1
    }

    # --------------------------------------------------
    print_action "Copying configuration files ..."
    cp --recursive "$config_dir" "$build_dir/" || {
        print_error "Failed to copy configuration files"
        return 1
    }

    # --------------------------------------------------
    print_action "Creating live image ..."
    lb build || {
        print_error "Failed to create live image"
        return 1
    }

    local target_image="$SCRIPT_DIR/${build_name}.iso"
    mv "$build_dir/live-image-amd64.hybrid.iso" "$target_image" || {
        print_error "Failed to move iso file"
        return 1
    }
    rm --recursive --force "$build_dir" || {
        print_error "Failed to remove build directory"
        return 1
    }

    # --------------------------------------------------
    print_okay "Build finished successfully"
    print_text "Iso image: $target_image"
    return 0
}

main "$@"
exit $?
