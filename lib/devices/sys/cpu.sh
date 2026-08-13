#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2155
# TERMAL INFO HANDLED IN temparature.sh
#
# there is lots of dead code in this file its becomming anoying

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

calculate_percent() {
    total_time1=$1
    total_time2=$2
    idle_time1=$3
    idle_time2=$4
    local total_delta=$(( total_time2 - total_time1 ))
    local idle_delta=$(( idle_time2 - idle_time1 ))
    local working_time=$(( total_delta - idle_delta ))
    local usage=$( bc -q <<< "scale=2; 100 * $working_time / $total_delta" )

    printf "%.2f%%" "$usage"
}

## refactor code and use read to set values 
calculate_cpu_usage() {
    # this function has code that ddodesnt do any thing 
    local -r interval=1
    local -r item_passed=$1
    local value_tc=""

    if [[ $item_passed == "cpu" ]]; then
        value_tc="^cpu "
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


calculate_core_usage() {
    local -A total_time1
    local -A total_time2
    local -A idle_time1
    local -A idle_time2
    local -A core_usage
    
    while read -r line; do 
        if [[ $line =~ ^cpu[0-9]+ ]]; then
            core_name=$(echo "$line" | awk '{print $1}')
            total_time1[$core_name]=$(echo "$line" | awk '{sum=0; for(i=2;i<=NF;i++){sum+=$i} print sum}')
            idle_time1[$core_name]=$(echo "$line" | awk '{print $5+$6}')
        fi
    done < "$CPU_USAGE_FILE"
    sleep 1

    while read -r line; do 
        if [[ $line =~ ^cpu[0-9]+ ]]; then
            core_name=$(echo "$line" | awk '{print $1}')
            total_time2[$core_name]=$(echo "$line" | awk '{sum=0; for(i=2;i<=NF;i++){sum+=$i} print sum}')
            idle_time2[$core_name]=$(echo "$line" | awk '{print $5+$6}')
        fi
    done < "$CPU_USAGE_FILE"

    for core in "${!total_time1[@]}"; do
            core_usage[$core]=$(calculate_percent "${total_time1[$core]}" "${total_time2[$core]}" \
            "${idle_time1[$core]}" "${idle_time2[$core]}")
            echo "$core=\"${core_usage["$core"]}\""

    done
}

get_load_average() {
    local load="$(cat $LOAD_INFO_FILE | awk '{printf "%.3f:%.3f:%.3f",$1, $2, $3}')"
    printf "%s" "$load"
}

get_cpu_usage() {
    local -r usage=$(calculate_cpu_usage "cpu")
    echo -en "$usage" ## i know you might want to use printf but don't it doesn't work i dont know why
}

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
        awk '{print $4}' $LOAD_INFO_FILE
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

# get cpu cache
# get cpu speed
# get core speed

write_cpu_config() {
    # using echo instead of printf cause its easier and quick modify for consistency
    CPU_CONFIG="$CONFIG_DIR/cpu.conf"
    mkdir -p "$CONFIG_DIR"
    {
        echo "cpu_model=\"$(get_cpu_model_info)\""
        echo "cpu_cores=\"$(get_cpu_cores)\""
        echo "cpu_usage=\"$(get_cpu_usage)\""
        echo "uptime=\"$(get_system_uptime)\""
        echo "load_average=\"$(get_load_average)\""
        echo "most_least_core=\"$(get_most_least_core)\"" # joining the info makes more sense than having to call the function twice
        calculate_core_usage

        IFS='/' read -r running_procs total_procs <<< "$(get_running_total)"
        echo "running_procs=\"$running_procs\""
        echo "total_procs=\"$total_procs\""
        
    } > "$CPU_CONFIG" 

}