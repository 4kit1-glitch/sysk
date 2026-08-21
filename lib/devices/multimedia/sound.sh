#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
    
run_pactl_list() {
    local OPTION1="$1"
    local OPTION2="${2:-}"
    # shellcheck disable=2086
    pactl list $OPTION1 $OPTION2 || {
        echo "pactl failed..." >&2
        return 0
    }
}
run_pactl() {
    local OPTION1="${1:-}"
    pactl "$OPTION1" || {
        echo "pactl failed..." >&2
    }
}

get_default_sink() {
    run_pactl get-default-sink
}

get_default_source() {
    run_pactl get-default-source
}

write_sink_json() {
    
    mkdir -p $CONFIG_DIR
    pactl -f json list sinks | \
    jq -f "$FEATURE_DIR"/build_sound.jq
}
write_source_json() {
    echo pass
}
