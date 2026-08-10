#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2086,2155
# fan speeds /sys/class/hwmon/fan*_input
# temparature
# - disk 
# - cpu and gpu
# - general system temparature


readonly SYSTEM_THERMAL_ZONE_PATH="/sys/class/thermal/thermal_zone"
readonly SYSTEM_THERMAL_ZONES=$(find "$SYSTEM_THERMAL_ZONE_PATH"*/type | wc -l)
readonly SYSTEM_FAN_INFO_PATH="/sys/class/hwmon"

convert_to_celsius() {
    # converts temp in millicelcius to celcius
    local -r value_tc=$1 # value to convert
    if [[ $value_tc =~ ^[0-9]+(\.[0-9]+)?$ ]]; then 
        celcius=$( bc -q <<< "scale=3; $value_tc / 1000" )
    elif [[ $value_tc == "N/A" ]]; then
        printf "N/A"
        return 1
    else
        printf "not a digit skipping!!!!" >&2
    fi
    printf "%.2f*C" "$celcius" 2> /dev/null
}
get_avg_temp() {
    # general system temparature
    local -i count=0
    local -i sum=0
    for zone in "$SYSTEM_THERMAL_ZONE_PATH"*; do
        if cat $zone/temp > /dev/null 2>&1; then 
            (( count++ ))
            sum=$(( sum + $(cat $zone/temp) ))
        fi
    done
    average="$(bc -q <<< "scale=3; $sum / $count")"
    convert_to_celsius "$average"
}
get_zone_temps() {
    for zone in "$SYSTEM_THERMAL_ZONE_PATH"*; do 
        echo "$(cat "$zone"/type)=\"$(convert_to_celsius \
            "$(cat $zone/temp  2> /dev/null || { printf "N/A"; })")\""
    done
}

get_fan_status() {
    # number of fans
    # could not properly get fan info like speed and ac 
    local fan_zones="$(find "$SYSTEM_FAN_INFO_PATH"/hwmon*/fan*_input 2> /dev/null | wc -l)"
    if (( fan_zones == 0 )); then
        printf "N/A"
    else
        printf "%d" "$fan_zones"
    fi
}

get_fan_speed() {
    local zones="$(get_fan_status)"
    if [[ $zones == "N/A" ]]; then
        printf "N/A"
    else
        for input in "$SYSTEM_FAN_INFO_PATH"/hwmon*/fan*_input; do 
            printf "%s=\"%s\"\n" "$(basename $input)" "$(cat $input)"
        done
    fi
}