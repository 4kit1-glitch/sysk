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

convert_to_celcius() {
    # converts temp in millicelcius to celcius
    local -r value_tc=$1 # value to convert
    if [[ $value_tc =~ ^[0-9]+$ ]]; then 
        celcius=$( bc -q <<< "scale=3; $value_tc / 1000" )
    elif [[ $value_tc == "N/A" ]]; then
        printf "N/A"
    else
        printf "not a digit skipping!!!!" >&2
    fi
    printf "%.2f*C" "$celcius"
}
get_avg_temp() {
    # general system temparature
    echo pass
}
get_zone_temps() {
    for zone in "$SYSTEM_THERMAL_ZONE_PATH"*; do 
        echo "$(cat "$zone"/type)=\"$(convert_to_celcius "$(cat $zone/temp  2> /dev/null || { printf "N/A"; })")\""
    done
}
get_cpu_temp() {
    echo pa
}

get_gpu_temp() {
echo pass
}

get_fan_status() {
    # number of fans
    # speed and status
    echo pass
}
get_zone_temps
