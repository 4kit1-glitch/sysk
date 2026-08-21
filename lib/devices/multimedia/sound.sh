#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
    
run_pactl_list() {
    local OPTION1="$1"
    local OPTION2="${2:-}"
    # shellcheck disable=2086
    pactl -f json list $OPTION1 $OPTION2 || {
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
    run_pactl_list sinks | \
    jq -f "$FEATURE_DIR"/build_sound.jq || {
        echo "sink write failed.." >&2
        return "$ERR_SUCCESS" 
    }
}
write_source_json() {
    run_pactl_list sources | \
    jq -f "$FEATURE_DIR"/build_sound.jq || {
        echo "source write failed.." >&2
        return "$ERR_SUCCESS" 
    }
}
write_sound_json() {
    local SOUND_CONFIG_FILE="$CONFIG_DIR/sound_$DATE.json"

    mkdir -p "$CONFIG_DIR"
    {
        jq -n \
        --slurpfile sinks <(write_sink_json 2> /dev/null ) \
        --slurpfile sources <(write_source_json 2> /dev/null ) \
        --arg dsource "$(get_default_source)" \
        --arg dsink "$(get_default_sink)" \
        '{sinks: $sinks[0], sources: $sources[0], defaults: {source: $dsource, sink: $dsink}}'
    } > "$SOUND_CONFIG_FILE" || {
        echo "sound write failed .." >&2
        return "$ERR_FAILURE"
    }
}