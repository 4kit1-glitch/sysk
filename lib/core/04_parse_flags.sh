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
# -q quit - no tui
# -c # clear data



# 
dump_records="off"

# reset
reset_records="off"

usage() { printf "%s\n" "\
usage: sysk \"[OPTIONS]\" \"[ARGS]\"

Sysk is a CLI system health monitor tool written in BASH and Python.
Sysk collects system information and produces an alert in case of a malfunction

NOTE: STILL IN DEVELOPMENT

OPTIONS:
-h      : display help menu and exit
-v      : display current version and exit
-r      : reset collected data
-q      : no tui
-c      : clear previous data and logs 

-d [module]     : display collected data on a given module
                - cpu, thermal, disk, memory

-D [module] [date]     : display collected data on a specified date [yyyy_mm_dd]"

exit 0
}