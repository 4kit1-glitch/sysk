#!/usr/bin/env bash
# cleanup and exit script for sysk

delete_file() {
    # deletes a specified log
    file="$1"

    [[ -f $file ]] || {
        echo "[ERROR]: file: $file not found" >&2
        exit 127
    }
    rm -f "$file" || {
        echo "[ERROR]: failed to remove $file"
        exit 1
    }
    return $?
}

clear_old_data() {
    # deletes files older than 3 days
    local directories=("$CONFIG_DIR" "$DUMPS_PATH" "$RESULT_DIR")
    for directory in "${directories[@]}"; do
        find "$directory" -type f -mtime +3 -print -delete 2> /dev/null ||  {
            printf "failed to remove old files\n"
            return "$ERR_FAILURE"
        }
    done
    return "$ERR_SUCCESS"
}

