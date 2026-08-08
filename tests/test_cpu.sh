#!/usr/bin/env bash
CPU_USAGE_FILE="/proc/stat"

get_most_least_core() {
    # this doesnt fucking work 
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
    echo "least=$least_used"
    echo "most=$most_used"
}

get_cpu_cores() {
    local core_count=$(cat "$CPU_INFO_FILE" | grep -ci "processor")
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
    done

    for core in "${!core_usage[@]}"; do 
        echo "$core=${core_usage["$core"]}%"
    done
}