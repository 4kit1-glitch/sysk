#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2034
# script check if program dependencies are installed and gets the missing ones

# array variable that stores the required dependencies of the program
declare -r required_deps=(
    "sed" "awk" "grep" "wc" "free"
    "dmidecode" "lscpu" "lsblk" "cat"
    "ls" "cd" "pwd" "dirname" "pactl"
    "aplay" "upower" "df" "info" "jq"
    "smartmontools" "acpi" "pactl"
)

declare -r required_files=(
    "/proc/meminfo" "/proc/cpuinfo" 
    "/proc/loadavg" "/proc/stat" "/proc/uptime"
)
declare -r required_dirs=(
    "/sys/block" "/sys/class/thermal/thermal_zone"
    "/sys/class/hwmon"
)

# variable stores the missing dependencies
declare -a missing_deps=()

get_missing_deps() {
    # function gets missing dependencies
    for dep in "${required_deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    [[ ${#missing_deps[@]} -eq 0 ]] && return 0 || return 1
}