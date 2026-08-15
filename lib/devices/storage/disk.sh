#!/usr/bin/env bash
#
#
# this performs disk checks and on disk drives and stores key info in disk.conf

run_smartctl() {
    # specifies and runs smartctl
    local flag="$1"
    local drive="${2:---scan}"

    run_privileged smartctl "$flag" "$drive"
}

mapfile -t drives < <(run_smartctl --scan | cut -d' ' -f 1) # store disk locations in a drives 

scan_disks() {
    [[ ${#drives[@]} -eq 0 ]] && {
        printf "no disk found!!" >&2
        return 1
    }
    for drive in "${drives[@]}"; do
        printf "%s\n" "$drive"
    done
}
get_disk_num() {
    scan_disks | wc -l
}


run_quick_disk_check() {
    echo pass
}

read_detailed_info() {
    echo pass
}