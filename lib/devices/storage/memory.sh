#!/usr/bin/env bash

# script carries functions that work with system memory info and test
# ext stands for extended
# ram size 
# used 
# available
# cached
# swap 
# used 
# availabel
# cache
# used
# available


# static
readonly MEM_INFO_FILE="/proc/meminfo"
readonly CPU_INFO_FILE="/proc/cpuinfo"


convert_to_unit() {
    # function converts to units to gigabytes
    local -r VALUE_TC="$1"
    local -r UNIT_FROM="$2"
    local -r UNIT_TO="$3"

    local -r allowed_units=(
        "MB" "KB" "GB" "B" "bits"
    )


}

#---------------RAM-----------------------------

get_installed_mem_num() {

}
get_total_mem() {

}
get_used_mem() {

}
get_available_mem() {

}
get_cached_mem() {

}
get_swap_mem() {

}
get_used_cached() {}
get_used_swap() {}
get_used_cache() {}

# cpu level memory
get_cpu_cache_info() {}

get_memory_device_info() {
}















































# quick details about ram 
get_short_ram_info() {
    local short_ram_info="$(
        free -h | sed -n '/Mem/p' | 
        awk '{ printf "total: %10s\nused: %11s\navailable: %6s", $2, $3, $7 end}' | 
        sed 's/Gi/Gb/'
    )"
    
    printf "%s\n" "$short_ram_info"
}

# full details about ram
get_full_ram_info() {
    run_privileged dmidecode -t memory | sed -E -n -f "$FEATURE_DIR/full_ram.sed" |
    awk 'BEGIN {PARAMETERS=8; printf "memory devices found \n"} NR % PARAMETERS == 1 {print "----- Device" ++n " -----"} { print }'

    return $?
}

#------------------ CACHE-------------------------

# quick info on the cache
get_short_cache_info() {
    short_cache_info="$(
        free -h | grep -Ei "Mem" | awk '{ printf "cache memory: %s\n", $6 }' | sed  s/Gi/Gb/
    )"
    printf "%s\n" "$short_cache_info"
}

# deep cpu cache details
get_ext_cache_info() {

    printf "%s\ncpu cache info\n%s\n" "$(get_short_cache_info)" \
    "$(lscpu | sed -E -n '/^L[[:digit:]]i?d?/p')"
    return $?
}

# ---------------- processes --------------------------
generate_memory_summary() {
    local -ri TOTAL_MEM_DEVICES="$(
        run_privileged dmidecode -t memory | 
        grep -Ei "Number of devices" | awk '{ print $4}'
    )"

    printf "Total number of memory devices %d\n" "$TOTAL_MEM_DEVICES"
    get_short_ram_info
    get_short_cache_info
    
    return $?
}