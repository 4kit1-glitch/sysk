#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
# handles hard disk information 
# ssd
# hdd
# usb drives

readonly DRIVE_DIR="/sys/block"
readonly DISK_STATS_FILE="/proc/diskstats"

mapfile -t drives < <(find "$DRIVE_DIR"/* -maxdepth 1 -printf "%f\n" | grep -Ev "(loops|ram|zram)") 


# to read
convert_to_gb() {
    # converts VALUES in 512 - byte sectors to gb
    local -r MULTIPLYER=512
    local -r DIVIDER=1073741824
    local -r VALUE="$1"
    local value_b=$(( VALUE * MULTIPLYER ))

    printf "%.1fGib" "$(bc -q <<< "scale=1; $value_b / $DIVIDER")" || {
        echo "function failed" 2> /dev/null
        return "$ERR_BAD_USAGE"
    }
}

disk_type_check() {
    # tests disk type
    echo pass

}

get_drives() {
    # reads and prints all drives
    for drive in "${drives[@]}"; do 
        printf "%s\n" "$drive"
    done
}

get_drive_size() {
    # prints the size of a specific drive
    echo pass
}

get_used_drive_space() {
    # get already used space
    echo pass
}

get_free_drive_space() {
    echo pass
}

get_usb_drives() {
    # prints usb drives
    echo pass
}

get_drive_partitions() {
    # prints partitions for every drive
    echo pass
}

write_disk_json() {
    # creates disk.json 
    echo pass
}
