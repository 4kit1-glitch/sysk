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
    printf "%.2f" "$celcius" 2> /dev/null
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
        echo "$(cat "$zone"/type)=$(convert_to_celsius \
            "$(cat $zone/temp  2> /dev/null || { printf "N/A"; })")"
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
write_thermal_json() {
    # multiple valiables needs to be fixed its unessessary
    # left out fan zone temps for now will do proper testing 
    local THERMAL_CONFIG="$CONFIG_DIR/thermal_$DATE.json"
    local avg_temp=$(get_avg_temp)
    local zone_temps=$(get_zone_temps)
    local fan_stats=$(get_fan_status)
    local fan_speed=$(get_fan_speed)


    local -a sensors
    local -a temps

    OLDIFS=$IFS
    IFS=$'\n'
    for zone_temp in $zone_temps; do 
        IFS='=' read -r sens temp <<< "$zone_temp"
        sensors+=("$sens")
        temps+=("$temp")
    done
    IFS=$OLDIFS

    local sensors_json=$(printf "%s\n" "${sensors[@]}" | jq -R . | jq -s '.')
    local temps_json=$(printf "%s\n" "${temps[@]}" | jq -R . | jq -s '.')


    local zone_temps_json=$(jq -n \
    --argjson names "$sensors_json"\
    --argjson values "$temps_json" \
    '[$names, $values] | transpose | map({(.[0]): (.[1])}) | add')


    
    mkdir -p "$CONFIG_DIR"

    jq -n --argjson atemp "$avg_temp" \
    --argjson zone_count "$SYSTEM_THERMAL_ZONES" \
    --argjson ztemps "$zone_temps_json" \
    --arg fan_status "$fan_stats" \
    --arg fan_spd "$fan_speed" \
    -f "$FEATURE_DIR"/build_thermal.jq > "$THERMAL_CONFIG"
}