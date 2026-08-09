#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2086,2155,2034
# fan speeds /sys/class/hwmon/fan*_input
# temparature
# - disk 
# - cpu and gpu
# - general system temparature


readonly SYSTEM_THERMAL_ZONE_PATH="/sys/class/thermal/thermal_zone"
readonly SYSTEM_THERMAL_ZONES=$(find $SYSTEM_THERMAL_ZONE_PATH* | wc -l)



get_avg_temp() {
    # general system temparature
    awk '
    BEGIN { sum = 0; count=0; max=0}
    {   
        sum += $1
        count++
        if ($1 > max) max = $1    
    }
    END {
        if (count == 0) {printf "N/A"; exit 1}
        avg = sum / (count * 1000)

        printf "%.2f*c", avg
    }' "$SYSTEM_THERMAL_ZONE_PATH"*/temp 2> /dev/null
}
get_zone_temps() {

}
get_cpu_temp() {

}

get_gpu_temp() {

}

get_fan_status() {
    # number of fans
    # speed and status

}