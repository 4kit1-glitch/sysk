#!/usr/bin/env bash
#
#
# this performs disk checks and on disk drives and stores key info in disk.conf


mapfile -t drives < <(run_smartctl --scan | cut -d' ' -f 1)

run_smartctl() {
    # specifies and runs smartctl
    flag="$1"
    drive="${2:---scan}"

    run_privileged smartctl "$flag" "$drive"
}

scan_disks() {
    run_smartctl --scan | cut -d' ' -f 1
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