#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
# shellcheck disable=2034
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
usage: sysk \"[OPTIONS]\" \"[ARGS]\"

Sysk is a CLI system health monitor tool written in BASH and Python.
Sysk collects system information and produces an alert in case of a malfunction

NOTE: STILL IN DEVELOPMENT

OPTIONS:
-h      : display help menu and exit
-v      : display current version and exit
-r      : reset collected data
-q      : no tui --settings

-d [module]     : display collected data on a given module
                - cpu, thermal, disk, memory
"
return $?
}

parse_args() {
    while getopts ':hvrd:' opt; do
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
                clean_cache && clean_logs || echo "cleaning failed" >&2
                echo "cleaning complete"
                exit 0
                ;;
            d)
                module=$OPTARG
                display_data "$module" || printf "Failed to display module" >&2
                exit 0
                ;;
            :)
                printf "option requires an argument: -%s" "$OPTARG"
                exit 0
                ;;
            \?)
                printf "unknown option: -%s\n" "$OPTARG" >&2
                usage
                exit 0
                ;;
        esac
    done
}
