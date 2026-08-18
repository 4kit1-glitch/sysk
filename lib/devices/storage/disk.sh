#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
# handles hard disk information 
# ssd
# hdd
# usb drives

readonly DRIVE_DIR="/sys/block"


mapfile -t drives < <(find "$DRIVE_DIR"/* -maxdepth 1 -printf "%f\n" | grep -Ev "(^loop|ram|zram)") 


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

get_drive_count() {
    printf "%d" "${#drives[@]}" || return "$ERR_FAILURE"
}

get_drives() {
    # reads and prints all drives
    for drive in "${drives[@]}"; do 
        printf "%s\n" "$drive"
    done
}


get_disk_type() {
    # tests disk type
    local -r DRIVE_NAME="$1"
    local -r ROTATIONAL_FILE="$DRIVE_DIR/$DRIVE_NAME/queue/rotational"
    local -r rot_value=$(cat "$ROTATIONAL_FILE")

    [[ -f $ROTATIONAL_FILE ]] || {
        printf "N/A"
        return "$ERR_NOT_FOUND"
    }

    if (( rot_value == 0 )); then 
        printf "SOLID STATE DRIVE"
    else
        printf "ROTATIONAL DISK DRIVE"
    fi
}

is_removable() {
    local -r DRIVE_NAME="$1"
    local -r REMOVABLE_FILE="$DRIVE_DIR/$DRIVE_NAME/removable"
    local -r rm_value=$(cat "$REMOVABLE_FILE")

    [[ -f $REMOVABLE_FILE ]] || {
        printf "N/A"
        return "$ERR_NOT_FOUND"
    }

    if (( rm_value == 0 )); then 
        printf "INTERNAL DISK"
    else
        printf "REMOVABLE DISK"
    fi
}

get_drive_size() {
    # prints the size of a specific drive
    local -r DRIVE_NAME="$1"
    local -r size_file="$DRIVE_DIR/$DRIVE_NAME/size"
    local -r size="$(cat "$size_file")"

    printf "%s" "$( convert_to_gb "$size")" || return "$ERR_FAILURE"
}

get_ro_value() {
    local -r DRIVE_NAME="$1"
    local -r RO_FILE="$DRIVE_DIR/$DRIVE_NAME/removable"

    [[ -f $RO_FILE ]] || {
        printf "N/A"
        return "$ERR_NOT_FOUND"
    }

    local -r ro_value=$(cat "$REMOVABLE_FILE")
    
    if (( ro_value == 0 )); then 
        printf "rw"
    else
        printf "r"
    fi
}
get_used_drive_size() {
    # get already used space
    echo pass
}

get_drive_partitions() {
    # prints partitions for every drive
    local drive="$1"
    local -r drive_path="$DRIVE_DIR/$drive/$drive"
    find "$drive_path"* -maxdepth 0
}

write_disk_json() {
    local DISK_CONFIG="$CONFIG_DIR/disk_$DATE.json"
    mkdir -p "$CONFIG_DIR"
    { 
        lsblk --output=name,size,fsuse%,fsused,ro,mountpoints,model,type -J | \
        jq '.blockdevices | map(select(.name | test("^(ram|zram|loop)"; "i") | not))'
    } > "$DISK_CONFIG"
}
