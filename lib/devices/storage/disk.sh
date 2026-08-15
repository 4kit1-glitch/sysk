#!/usr/bin/env bash
#
#
# this performs disk checks and on disk drives and stores key info in disk.conf


mapfile -t drives < <(run_smartctl --scan | cut -d' ' -f 1)

run_smartctl() {
    # specifies and runs smartctl
    local flag="$1"
    local drive="${2:---scan}"

    run_privileged smartctl "$flag" "$drive"
}

scan_disks() {
    for drive in "${drives[@]}"; do
        printf "%s\n" "$drive"
}
echo "${drives[*]}"

get_disk_num() {
    scan_disks | wc -l
}


run_quick_disk_check() {
    echo pass
}

read_detailed_info() {
    echo pass
}