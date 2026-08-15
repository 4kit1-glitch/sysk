#!/usr/bin/env bash
#
#
# this performs disk checks and on disk drives and stores key info in disk.conf
readonly DRIVE_DIR="/sys/block"


run_smartctl() {
    # specifies and runs smartctl
    local flag="$1"
    local drive="${2:---scan}"

    run_privileged smartctl "$flag" "$drive"
}

# store disk locations in a drives 
mapfile -t drives < <(find "$DRIVE_DIR"/* -maxdepth 1 -printf "%f\n" | grep -Ev "(loops|ram|zram)") 

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
    printf "%d" "${#drives[@]}"
}

run_quick_disk_check() {
    num=$(get_disk_num)
    for drive in "${drives[@]}"; do
        run_smartctl -H "/dev/$drive" | grep -Eio "(passed|failed|ok)" || {
            echo "failed"
        }
    done
}