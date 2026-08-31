#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# 
# getops and flag parser script
#

# -d or --dump
# -h or --help
# -v or --version
# -r or --reset
# -m {module name} specific module info
# -q quiet - no tui
# -c # clear data


usage() { printf "%s\n" "\
(usage: sysk \"[OPTIONS]\" \"[ARGS]\")

Sysk is a CLI system health monitor tool written in BASH and Python.
Sysk collects system information and produces an alert in case of a malfunction

NOTE: STILL IN DEVELOPMENT

OPTIONS:
-h      : display help menu and exit
-v      : display current version and exit
-r      : reset collected data

-m [module]     : display collected data on a given module
                - cpu, thermal, disk, memory
"
return $?
}

display_data() {
    # display most resent data
    path="$1"
    find "$CONFIG_DIR/$path"* -printf "%p\n" 2> /dev/null | sort -rn | head -1 | xargs jq . || return "$ERR_FAILURE"
    return $?
}
parse_args() {
    while getopts ':hvrm:' opt; do
        case "$opt" in
            h)
                usage || echo "cant generate help" >&2
                exit 0
                ;;
            v) 
                echo "$PROGNAME version $VERSION"
                exit 0
                ;;
            r)
                clear_old_data || echo "cleaning failed" >&2
                echo "cleaning complete"
                exit 0
                ;;
            m)
                display_data "$OPTARG" || {
                    printf "Failed to display module" >&2
                    exit "$ERR_FAILURE"
                }
                exit "$ERR_SUCCESS"
                ;;
            :)
                printf "option requires an argument: -%s\n" "$OPTARG" >&2
                usage >&2
                exit "$ERR_FAILURE"
                ;;
            \?)
                printf "unknown option: -%s\n" "$OPTARG" >&2
                usage >&2
                exit "$ERR_FAILURE"
                ;;
        esac
    done
}