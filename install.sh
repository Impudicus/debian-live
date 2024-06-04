#!/bin/bash

# constants
readonly script_name=${BASH_SOURCE[0]}
readonly script_path=$(dirname $(realpath ${BASH_SOURCE[0]}))
readonly script_start=${SECONDS}

# configurations
set -o errexit  # exit on error
set -o pipefail # return exit status on pipefail

runInstall() {
    # apt update
    apt update
    apt upgrade --yes
    apt full-upgrade --yes

    # install syslinux
    apt install --yes \
        syslinux \
        syslinux-efi \
        syslinux-utils \
        isolinux

    # install live-build
    apt install --yes \
        live-build \
        live-manual \
        live-tools
}

runBuild() {
    (
        cd "${build_dir}"

        # cleanup config
        if [[ -d "${PWD}/chroot" ]]; then
            lb clean
        fi

        # create config
        if [[ ! -d "${PWD}/auto" || ! -d "${PWD}/local" ]]; then
            override_hostname="${override_hostname:-debian-live}"
            override_username="${override_username:-debian}"
            override_password="${override_password:-live}"

            lb config \
                --mode "debian" \
                --distribution "bookworm" \
                --debian-installer "none" \
                --architectures "amd64" \
                --archive-areas "main contrib non-free non-free-firmware" \
                --bootappend-live "boot=live components locales=de_DE.UTF-8 keyboard-layouts=de hostname=${override_hostname} username=${override_username}" \
                --debootstrap-options "--variant=minbase"
        fi

        # add content
        local source_dir="/var/lib/clamav/"
        local target_dir="${PWD}/config/includes.chroot_after_packages/var/lib/clamav"
        mkdir --parents "${target_dir}"

        cp  ${source_dir}/bytecode.* \
            ${source_dir}/daily.* \
            ${source_dir}/main.* \
            ${source_dir}/freshclam.dat \
            ${target_dir}

        # build config
        lb build
    )
}

printLog() {
    local log_type="${1}"
    local log_text="${2}"

    case "${log_type}" in
        error)
            printf "${script_name}: \e[41m${log_text}\e[0m\n" >&2
            ;;
        okay)
            printf "${script_name}: \e[42m${log_text}\e[0m\n" >&1
            ;;
        info)
            printf "${script_name}: \e[44m${log_text}\e[0m\n" >&1
            ;;
        *)
            printf "${script_name}: ${log_text}\n" >&1
            ;;
    esac
}

printHelp() {
    printf "Usage: ${script_name} [OPTIONS] Action\n"
    printf "Options:\n"
    printf "  -h, --help        Show this help message.\n"
    printf "\n"
    printf "Actions:\n"
    printf "  build             Build live-image with specified configuration.\n"
    printf "  install           Install requirements for live-build environment.\n"
    printf "\n"
}

main() {
    # pre-checks
    if [[ "${EUID}" -ne 0 ]]; then
        printLog "error" "Script has to be run with root user privileges."
        exit 1
    fi

    build_dir="${script_path}/build"
    if [[ ! -d "${build_dir}" ]]; then
        printLog "error" "Unable to find build folder in the specified directory."
        exit 1
    fi

    # variables
    override_hostname=""
    override_username=""
    override_password=""

    # parameters
    if [[ $# -eq 0 ]]; then
        printLog "error" "Missing action, use --help for further information."
        exit 1
    fi

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            build)
                printLog "info" "Task running: Create live-build ..."
                runBuild
                break
                ;;
            install)
                printLog "info" "Task running: Install requirements ..."
                runInstall
                break
                ;;
            -h | --help)
                printHelp
                exit 0
                ;;
            *)
                printLog "error" "Unknown option '${1}', use --help for further information."
                exit 1
                ;;
        esac
    done

    # run

    printLog "okay" "Script executed successfully."
    exit 0
}

main "$@"
