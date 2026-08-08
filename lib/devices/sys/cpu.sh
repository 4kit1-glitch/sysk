#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2155
# TERMAL INFO HANDLED IN temparature.sh
#

readonly CONFIG_DIR="$XDG_CONFIG_HOME"

# static info
readonly CPU_INFO_FILE="/proc/cpuinfo"
readonly LOAD_INFO_FILE="/proc/loadavg"
readonly CPU_USAGE_FILE="/proc/stat"
readonly UPTIME_INFO_FILE="/proc/uptime"

get_cpu_model_info() {
    [[ -f "$CPU_INFO_FILE" ]] && { \
        local model_name="$(cat $CPU_INFO_FILE | \
        grep -i "model name" | \
        awk -F':' '{print $2}' | head -1)"
    }
    printf "%s" "$model_name"
}

get_cpu_cores() {
    local core_count=$(cat $CPU_INFO_FILE | grep -ci "processor")
    printf "%d" "$core_count"
}

## refactor code and use read to set values 
calculate_usage() {
    local -r interval=1
    local -r item_passed=$1
    local value_tc=""

    if [[ $item_passed =~ (^cpu |^CPU |^cpu) ]]; then
        value_tc="^cpwrite_cpu_configu "
    elif [[ $item_passed =~ (^cpu[0-9]+) ]]; then 
        value_tc="$item_passed"
    else
        printf "cannot calculate usage of %s not available" "$item_passed" >&2
        return "$ERR_BAD_USAGE"
    fi

    read -r total_time1 idle_time1 < <( \
        awk -v var="$value_tc" 'BEGIN {sum=0} 
            $0 ~ var {for(i=2; i<=NF; i++){sum += $i} 
            {printf "%d %d", sum, $5+$6}} # idle + iowait
            ' \
        $CPU_USAGE_FILE)

    sleep "$interval"

    read -r total_time2 idle_time2 < <( \
        awk -v var="$value_tc" 'BEGIN {sum=0} 
            $0 ~ var {for(i=2; i<=NF; i++){sum += $i} 
            {printf "%d %d", sum, $5+$6}}
            ' \
        $CPU_USAGE_FILE)
    
    local total_delta=$(( total_time2 - total_time1 ))
    local idle_delta=$(( idle_time2 - idle_time1 ))
    local working_time=$(( total_delta - idle_delta ))
    local usage=$( bc -q <<< "scale=2; 100 * $working_time / $total_delta" )

    printf "%.2f%%" "$usage"
}
get_load_average() {
    local load="$(cat $LOAD_INFO_FILE | awk '{print $1 $2 $3}')"
    printf "%s" "$load"
}

get_cpu_usage() {
    local -r usage=$(calculate_usage "cpu")
    echo -en "$usage" ## i know you might want to use printf but don't it doesn't work i dont know why
}


get_cores_usage() {
    # this function is quite slow cause it waits the core amount times in seconds 
    # might need refatoring 
    # avoid running if possible
    # actually gets the info but will process later
    local -r CORES=$(get_cpu_cores)
    local -A core_usages

    # first set core usage percentages
    for (( i=0; i<CORES; i++ )); do
        core_usages["cpu$i"]=$(calculate_usage "cpu$i")
    done

    for core in "${!core_usages[@]}"; do 
        echo "$core=${core_usages["$core"]}"
    done

}

# fix this
get_most_least_core() {
    # processing requires setting IFS=':'
    least_used=$( \
        awk 'BEGIN {idle = 0; max = 0} 
        /^cpu[0-9]+/ {
            idle=$5+$6; 
            if(idle >= max) {max=idle; name=$1}
        }
        END {printf "%s", name}' $CPU_USAGE_FILE \
    )
    most_used=$( \
        awk 'BEGIN {total = 0; max = 0; name=""}
        /^cpu[0-9]+/ {
        total=$2+$3+$4; 
        if(total >= max){ name=$1; max=total;} 
        } END {printf "%s", name}' $CPU_USAGE_FILE \
    )
    printf "%s:%s" "$most_used" "$least_used"
}

get_running_total() {
    # function reads processes running and total processes from loadavg
    # think its better to get them both then process at need rather than individually
    # maybe will improve later
    local running_total=$( \
        awk 'print $' $LOAD_INFO_FILE
    )
    printf "%s" "$running_total"
}

get_system_uptime() {
    read -r uptime_secs idle_secs < $UPTIME_INFO_FILE

    local uptime_mins=$( bc -q <<< "scale=0; $uptime_secs / 60")
    local uptime_hrs=$( bc -q <<< "scale=0; $uptime_mins / 60")
    local uptime_days=$( bc -q <<< "scale=0; $uptime_hrs / 24")
    local uptime_weeks=$( bc -q <<< "scale=0; $uptime_days / 7")

    # output order is secs:mins:hrs:days:weeks:idle_secs
    printf "%s:%s:%s:%s:%s:%s" \
        "$uptime_secs" "$uptime_mins" "$uptime_hrs" "$uptime_days" "$uptime_weeks" "$idle_secs"
}



write_cpu_config() {
    CPU_CONFIG="$CONFIG_DIR/cpu.conf"
    mkdir -p "$CONFIG_DIR"
    {
        echo "cpu_model=\"$(get_cpu_model_info)\""
        echo "cpu_cores=\"$(get_cpu_cores)\""
        echo "cpu_usage=\"$(get_cpu_usage)\""
        echo "uptime=\"$(get_system_uptime)\""
        echo "load_average=\"$(get_load_average)\""

    } > "$CPU_CONFIG" 

}
get_cores_usage