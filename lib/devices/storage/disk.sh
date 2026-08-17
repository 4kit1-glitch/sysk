#!/usr/bin/env bash
# vim: noai:ts=4:sw=4:expandtab
# shellcheck source=/dev/null
#
# handles hard disk information 
# ssd
# hdd
# usb drives

readonly DRIVE_DIR="/sys/block"
readonly DISK_STATS_FILE="/proc/diskstats"

