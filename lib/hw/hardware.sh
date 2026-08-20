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
    if [[ ! -f "$DMI_CACHE" ]]; then
        run_privileged dmidecode -t 0,1,2,4,16,17,22,39 > "$DMI_CACHE"
    else 
        return "$ERR_SUCCESS"
    fi
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
get_processor_type() {
    read_dmi 4 "Type"
}

get_processor_family() {
    read_dmi 4 "Family"
}
get_processor_version() {
    read_dmi 4 "Version"
}
get_max_speed() {
    read_dmi 4 "Max"
}
get_current_speed() {
    read_dmi 4 "Current"
}

#---------------physical memory space-----------------------------

get_installed_mem_num() { 
    read_dmi 16 "Number" 
}
get_maximum_capacity() {
    read_dmi 16 "Maximum"
}

write_hardware_json() {
    local HARDWARE_CONFIG="$CONFIG_DIR/hardware_$DATE.json"

    init_dmi_cache || { 
        echo "failed to initialize cache" >&2
        return "$ERR_FAILED" 
    }

    mkdir -p "$CONFIG_DIR"
    jq -n --arg dump "$DMI_CACHE" \
    --arg vendor "$(get_vendor)" \
    --arg firmware_version "$(get_firmware_version)" \
    --arg release_date "$(get_release_date)" \
    --arg manufacturer "$(get_manufacturer)" \
    --arg prod_name "$(get_product_name)" \
    --arg serial_num "$(get_serial_number)" \
    --arg processor_type "$(get_processor_type)" \
    --arg processor_family "$(get_processor_family)" \
    --arg processor_version "$(get_processor_version)" \
    --arg max_sp "$(get_max_speed)" \
    --arg current_sp "$(get_current_speed)" \
    --arg mem_num "$(get_installed_mem_num)" \
    --arg max_capacity "$(get_maximum_capacity)" \
    -f "$FEATURE_DIR"/build_hardware.jq > "$HARDWARE_CONFIG"
}