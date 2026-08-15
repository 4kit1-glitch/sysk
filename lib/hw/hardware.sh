#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
# script reads hardware info 
# uses mainly dmidecode and programs
# cpu
# gpu
# cooling
# system
# bios
# memory
# disks

read_dmi() {
    # function is a wrapper to dmidecode
    local -r TYPE="$1"
    local -r FIELD="$2"

    run_privileged dmidecode -q -t "$TYPE" | awk -F': ' -v field="$FIELD" '$0 ~ "^[[:space:]]*"field {print $2}'
}

#---------------RAM-----------------------------
# processing dmidecode
get_installed_mem_num() { 
    read_dmi 16 "Number" 
}
get_maximum_capacity() {
    read_dmi 16 "Maximum"
}



