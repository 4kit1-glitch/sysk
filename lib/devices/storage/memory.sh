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
                    result=$(bc -q <<< "scale=2; $VALUE_TC / $MULTIPLYER / $MULTIPLYER ")
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
    difference="$(bc -q <<< "scale=2; $(get_total_mem | awk '{print $1}') - $(get_available_mem | cut -d' ' -f 1)")"
    convert "$difference" "KB"
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
get_used_cached() {
    # calculates and echos used cached
    echo pa
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
    echo pa
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
    echo pass
}

#----------OTHERS-------------------
get_hardware_corrupted() {
    # reads bad ram pages
    read_meminfo "HardwareCurrupted"
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
        echo "total_mem=\"$(get_mem_total)\""
        echo "total_mem=\"$()\""
        echo "total_mem=\"$()\""
        echo "total_mem=\"$()\""
        echo "total_mem=\"$()\""
        echo "total_mem=\"$()\""

    } > "$MEM_CONFIG"

}

get_used_mem