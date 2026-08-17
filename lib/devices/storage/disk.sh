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
    # converts
    echo pass

}

disk_type_check() {
    # tests disk type
    echo pass

}

get_drives() {
    # reads and prints all drives
    for drive in ${drives[@]}; do 
        printf "%s\n" "$drive"
    done
}

get_drive_size() {
    # prints the size of a specific drive
}

get_used_drive_space() {
    # get already used space
}

get_free_drive_space() {

}

get_usb_drives() {
    # prints usb drives

}

get_drive_partitions() {
    # prints partitions for every drive
}

write_disk_json() {
    # creates disk.json 

}