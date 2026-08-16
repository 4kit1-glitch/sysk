#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2034
#
# script performs a wrapper to sudo
# return err codes are assigned in 00_error.sh
# if syskit is run as cron then user must use sudo crontab -e not handling NOPASSWD for secuirity reasons

run_with_sudo() { sudo "$@"; }

is_root() {
    [[ $EUID -eq 0 ]] && {
        return "$ERR_SUCCESS"
    }
    return "$ERR_FAILURE"
}

is_sudo_available() {
    command -v sudo > /dev/null 2>&1 && {
        return "$ERR_SUCCESS"
    }
    return "$ERR_FAILURE"
}
is_sudo_active() {
    sudo -n true > /dev/null 2>&1 && {
        return "$ERR_SUCCESS"
    }
    return "$ERR_FAILURE"
}

# gives a process super user privileges
run_privileged() {
    # check if user runs as root 
    if is_root; then  
        "$@"
        return $?
    elif  ( ! is_root && ! is_sudo_available ); then
        printf "sudo not available\n" >&2
        printf "run as root or set up sudo\n" >&2
        return "$ERR_NOT_FOUND"
    elif ! is_sudo_active; then 
        read -rp "Process requires super user privileges: proceed with sudo? [y/n]: " response
        [[ $response =~ ^[Yy]$ ]] && {
            run_with_sudo "$@"
            return $?
        }
        printf "permission denied -- process aborted\n" >&2
        return "$ERR_FAILURE"
    else
        run_with_sudo "$@"
        return $?

    fi
}

# remove sudo privileges
kill_sudo() {
    is_sudo_active && {
        sudo -k
        return "$ERR_SUCCESS"
    }
    printf "sudo not active !!! aborting..." >&2
    return "$ERR_BAD_USAGE"
}