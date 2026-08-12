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


convert() {
    local -ri MULTIPLYER=1024
    # function converts to units to Megabytes
    local -r VALUE_TC="$1"
    local -r UNIT_FROM="$2"
    local result
    if [[ $UNIT_FROM =~ ([Mm][Bb]|[kK][bB]|[gG][bB]) ]]; then
            case $UNIT_FROM in 
                "MB")
                    result="$VALUE_TC"
                    ;;
                "KB")
                    result="$(bc -q <<< "$VALUE_TC * $MULTIPLYER")"
                    ;;
                "GB")
                    result=$(bc -q <<< "scale=3; $VALUE_TC / $MULTIPLYER")
                    ;;
            esac
    else
        printf "Invalid use" >&2
        exit 2
    fi
    printf "%s Mb" "$result"
}

#---------------RAM-----------------------------

get_installed_mem_num() {
    run_privileged dmidecode -q -t 16 | awk -F': ' '/^[[:space:]]Number/ {print $2}'
}
get_total_mem() {
    echo pass
}
get_used_mem() {
    echo pass
}
get_available_mem() {
    echo pa
}
get_cached_mem() {
    echo pa
}
get_swap_mem() {
    echo pa
}
get_used_cached() {
    echo pa
}
get_used_swap() {
    echo pa
}
get_used_cache() { 
    echo pa
}

# cpu level memory
get_cpu_cache_info() {
    echo pa
}

get_memory_device_info() {
    echo pa
}


convert 1000 "MB"












































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