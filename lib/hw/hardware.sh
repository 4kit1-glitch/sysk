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


readonly DMI_CACHE="$DUMPS_PATH/dmi_$DATE.cache"

init_dmi_cache() {
    # the info gotten is kinda static meaning tracking with date deosn't is not proper 
    [[ ! -f "$DMI_CACHE" ]] && run_privileged dmidecode -t 0,1,2,4,16,17,22,39 > "$DMI_CACHE" || {
        printf "cache already initialized...\n" >&2
        return "$ERR_FAILURE"
    }
}
read_dmi() {
    local -r TYPE="$1"
    local -r FIELD="$2"

    cat "$DMI_CACHE" | sed -n "/type $TYPE,/,/^$/p" | \
    awk -F': ' -v field="$FIELD" '$0 ~ "^[[:space:]]*"field {print $2}'
}


#----- platform firmware-----

get_vendor(){
    read_dmi 0 "Vendor" || {
        printf "N/A" >&2
        return "$ERR_SUCCESS"
    }
}

get_firmware_version() {
    read_dmi 0 "Version"
}

get_release_date() {
    read_dmi 0 "Release Date"
}


# --- system information-----
get_manufacturer() {
    read_dmi 1 "Manufacturer"
}

get_product_name() {
    read_dmi 1 "Product"
}
get_system_version() {
    read_dmi 1 "Version"
}

get_serial_number() {
    read_dmi 1 "Serial"
}

# ------- processor info -----------
get_processorr_type() {
    read_dmi 4 "Type"
}

get_processor_family() {
    read_dmi 4 "Family"
}
get_processor_version() {
    read_dmi 4 "Version"
}
get_max_speed() {
    read_dmi 4
}
get_current_speed() {
    read_dmi 4
}

#---------------physical memory space-----------------------------
# processing dmidecode
get_installed_mem_num() { 
    read_dmi 16 "Number" 
}
get_maximum_capacity() {
    read_dmi 16 "Maximum"
}
