#!/usr/bin/env bash
# shellcheck source=/dev/null
# shellcheck disable=2034
#
# script defines and stored error codes used in the program
# code convension: ERR_WHAT_IT_REPRESENTS
# make it as short as possible

readonly ERR_SUCCESS=0  # operation successfule
readonly ERR_FAILURE=1  # operation failed general 
readonly ERR_PERMISSION_DENIED=126 # permission denied
readonly ERR_COMMAND_FAILED=126 # command runs but fails
readonly ERR_NOT_FOUND=127  # command or file not found
readonly ERR_BAD_USAGE=2    # bad use of script or function
readonly SYSTEM_BAD=90 # special variable


