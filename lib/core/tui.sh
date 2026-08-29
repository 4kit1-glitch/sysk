#!/usr/bin/env bash
# simple ui for syk


C_RESET="\033[0m"
C_OK="\033[1;32m"
C_WARN="\033[1;33m"
C_CRIT="\033[1;31m"
C_HEADER="\033[1;36m"

print_banner() {
    echo -e "${C_HEADER}"
    cat "$FEATURE_DIR/enso_ascii.kit" 2> /dev/null || echo "SYSK"
    echo -e "${C_RESET}"
}

status_color() {
    status="$1"
    case "$status" in
        OK) echo -e "$C_OK" ;;
        WARNING) echo -e"$C_WARN" ;;
        CRITICAL) echo "$C_CRIT" ;;
        *) echo "$C_RESET" ;;
    esac
}

build_info() {
    local result_file
    result_file="$(find "$RESULT_DIR/result_$DATE"* -printf "%p\n" | sort -rn | head -1)"
    jq 'to_entries[] |  "\(.key) |\(.value.status) | \(.value.value)"' "$result_file" | \
    while IFS='|' read -r key status value; do 
        local color
        color=$(status_color "$status")
        printf "%-22s%-10s%s\n" "${key^^}" "$status" "$value"
    done
    return $?
}

display_tui() {
    build_info || {
        printf "failed to display" >&2
        return "$ERR_FAILURE"
    }
    return $?
}