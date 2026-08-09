#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2086,2155,2034
# fan speeds /sys/class/hwmon/fan*_input
# temparature
# - disk 
# - cpu and gpu
# - general system temparature


readonly SYSTEM_THERMAL_ZONE_FILE="/sys/class/thermal/thermal_zone*"
readonly SYSTEM_THERMAL_ZONES=$(find /sys/class/thermal/thermal_zone* | wc -l)


get_avg_temp(){
    # general system temparature, mother board and 
    # average_temp = average temparature in degree celcius 
    # total_millic combined system temparature from all thermal zones
    local total_millic=$(paste $SYSTEM_THERMAL_ZONE_FILE/temp 2> /dev/null | \
        awk 'BEGIN{sum=0}{for(i=1; i<=NF; i++)sum+=$i} END {print sum / (i * 1000)}')
    local average_temp=$(bc -q <<< "scale=2; $total_millic / 1000")
    echo $total_millic
    printf "%.2f*C" "$average_temp"
}
get_avg_temp