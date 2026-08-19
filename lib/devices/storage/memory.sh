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

convert() {
    # function converts to units to Megabytes
    local -ri MULTIPLYER=1024
    local -r VALUE_TC="$1"
    local -r UNIT_FROM="$2"
    local result
    if [[ $UNIT_FROM =~ ([Mm][Bb]|[kK][bB]|[gG][bB]) ]]; then
            case $UNIT_FROM in 
                "MB") result="$VALUE_TC";;
                "KB") result="$(bc -q <<< "scale=1; $VALUE_TC / $MULTIPLYER")" ;;
                "GB")
                    result=$(bc -q <<< "scale=2; $VALUE_TC * $MULTIPLYER")
                    ;;
            esac
    else
        printf "Invalid use" >&2
        exit 2
    fi
    printf "%s Mb" "$result"
}


read_meminfo() {
    # reads and extract appropraite data from /proc/meminfo
    local -r FIELD="$1"
    convert "$(cat $MEM_INFO_FILE | awk -v field="$FIELD" '$0 ~ "^"field {print $2}')" "KB"
}


#---------- RAM ---------------
get_total_mem() {
    # get total memory
    read_meminfo "MemTotal"
}
get_available_mem() {
    # get available memory
    read_meminfo "MemAvailable"
}
get_used_mem() {
    # gets used memory
    local difference
    difference="$(bc -q <<< \
        "scale=2; $(get_total_mem | awk '{print $1}') - $(get_available_mem | cut -d' ' -f 1)")"
    printf "%.2f Mb" "$difference"
}

# ------ CACHE / BUFFERS -----------------
get_cached_mem() {
    # get cached memory
    read_meminfo "Cached"
}
get_buffered_mem() {
    read_meminfo "Buffers"
}
get_swap_cache() {
    # gets double buffered swap
    read_meminfo "SwapCached"
}

# --------- SWAP-------------
get_swap_mem() {
    # gets swap memory
    read_meminfo SwapTotal
}
get_free_swap() {
    # gets unused swap
    read_meminfo SwapFree
}

get_used_swap() {
    # calculates used swap
    local difference
    difference="$(bc -q <<< \
        "scale=2; $(get_swap_mem | awk '{print $1}') - $(get_free_swap | cut -d' ' -f 1)")"
    printf "%.2f Mb" "$difference"
}

# -------- VIRTUAL MEMORY -----------
get_virtual_mem() {
    # gets total virtual memory
    read_meminfo "VmallocTotal"
}

get_used_virtual() {
    # gets uded virtual memory
    read_meminfo "VmallocUsed"
}

get_free_virtual() {
    # gets ramaining virtual mem
    local difference
    difference="$(bc -q <<< \
        "scale=2; $(get_virtual_mem | awk '{print $1}') - $(get_used_virtual | cut -d' ' -f 1)")"
    printf "%.2f Mb" "$difference"

}

#----------OTHERS-------------------
get_hardware_corrupted() {
    # reads bad ram pages
    read_meminfo "HardwareCorrupted"
}

get_unevictable_mem() {
    # reads ram locked by kernel
    read_meminfo "Unevictable"
}

get_balloon_mem() {
    # gets Ballon memory thats used by Virtual machines
    read_meminfo "Balloon"
}

get_dirty_mem() {
    # gets memory waiting to write to disk
    read_meminfo "Dirty"
}
get_anon_pages() {
    # reads anonpage size
    read_meminfo "AnonPages"
}


write_memory_config() {
    # writes memory config file
    local MEM_CONFIG="$CONFIG_DIR/memory.conf"

    mkdir -p "$CONFIG_DIR"
    {
        echo "total_mem=\"$(get_total_mem)\""
        echo "available_mem=\"$(get_available_mem)\""
        echo "used_mem=\"$(get_used_mem)\""
        echo "cached_mem=\"$(get_cached_mem)\""
        echo "buffer=\"$(get_buffered_mem)\""
        echo "swap_cache=\"$(get_swap_cache)\""
        echo "swap_mem=\"$(get_swap_mem)\""
        echo "swap_free=\"$(get_free_swap)\""
        echo "swap_used=\"$(get_used_swap)\""
        echo "virtual_mem=\"$(get_virtual_mem)\""
        echo "used_virtual=\"$(get_used_virtual)\""
        echo "free_virtual=\"$(get_free_virtual)\""
        echo "corrupted=\"$(get_hardware_corrupted)\""
        echo "unevicted=\"$(get_unevictable_mem)\""
        echo "balloon=\"$(get_balloon_mem)\""
        echo "dirty=\"$(get_dirty_mem)\""
        echo "anon_pages=\"$(get_anon_pages)\""

    } > "$MEM_CONFIG"
}


write_memory_json() {
    local MEM_CONFIG="$CONFIG_DIR/memory_$DATE.json"

    mkdir -p "$CONFIG_DIR"

    jq --args total_mem "$(get_total_mem)" \
        --args available_mem "$(get_available_mem)" \
        --args used_mem"$(get_used_mem)" \
        --args cached_mem"$(get_cached_mem)" \
        --args buffer "$(get_buffered_mem)" \
        --args swap_cache "$(get_swap_cache)"\
        --args swap_mem "$(get_swap_mem)" \
        --args swap_free "$(get_free_swap)" \
        --args swap_used "$(get_used_swap)" \
        --args virtual_mem"$(get_virtual_mem)" \
        --args used_virtual "$(get_used_virtual)" \
        --args free_virtual "$(get_free_virtual)" \
        --args corrupted "$(get_hardware_corrupted)" \
        --args unevicted "$(get_unevictable_mem)" \
        --args balloon "$(get_balloon_mem)" \
        --args dirty "$(get_dirty_mem)" \
        --args anon_pages "$(get_anon_pages)" \
    -f "$FEATURE_DIR"/build_memory.jq > "$MEM_CONFIG"
}