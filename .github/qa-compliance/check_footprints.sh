#!/usr/bin/env bash

shopt -s nullglob

#
# The MIT License (MIT)
# Copyright (c) 2022 Li-Pro.Net (Stephan Linz)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.
#

SCRIPT_NAME="${0##*/}"
SCRIPT_PATH="$( cd "${0%/*}" && pwd -P )"
SCRIPT_LOG="$( pwd -P )/${SCRIPT_NAME%.*}.log"
METRICS_TXT="$( pwd -P )/metrics.txt"
METRICS_FOOTPRINTS_TXT="${METRICS_TXT%.*}_footprints.txt"

declare -i ERROR_CNT=0
declare -i ERROR_MAX=$((0xff))-5

# Enable fast exit for the check-up phase.
set -e

# Looking for helper tools in PATH environment variable.
PY3="$( type -P "python3" )" || ( \
        echo "Executable not found: 'python3'" >&2 ; exit 255 )
TCH="$( type -P "touch" )" || ( \
        echo "Executable not found: 'touch'" >&2 ; exit 255 )
TEE="$( type -P "tee" )" || ( \
        echo "Executable not found: 'tee'" >&2 ; exit 255 )
AWK="$( type -P "awk" )" || ( \
        echo "Executable not found: 'awk'" >&2 ; exit 255 )
AWK_WARNINGS='/^.*\.warnings[[:blank:]]*[[:digit:]]*$/ {warnings+=$2;} END {print warnings;}'
AWK_ERRORS='/^.*\.errors[[:blank:]]*[[:digit:]]*$/ {errors+=$2;} END {print errors;}'
MOV="$( type -P "mv" )" || ( \
        echo "Executable not found: 'mv'" >&2 ; exit 255 )

# Make sure the logging output file is writable.
"${TCH}" -m "${SCRIPT_LOG}"
:> "${SCRIPT_LOG}"

# Make sure the metrics output file is writable.
"${TCH}" -m "${METRICS_FOOTPRINTS_TXT}"
"${TCH}" -m "${METRICS_TXT}"

# Looking for needed runtime variables from global environment.
[ -v "UTILS" -a -n "${UTILS}" -a -d "${UTILS}" ] || \
( echo "Environment variable or folder not found: 'UTILS'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 254 )
UTILS="$( cd "${UTILS}" && pwd -P )"
[ -v "NEWLIBS" -a -n "${NEWLIBS}" -a -d "${NEWLIBS}" ] || \
( echo "Environment variable or folder not found: 'NEWLIBS'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 254 )
NEWLIBS="$( cd "${NEWLIBS}" && pwd -P )"
[ -v "OLDLIBS" -a -n "${OLDLIBS}" -a -d "${OLDLIBS}" ] || \
( echo "Environment variable or folder not found: 'OLDLIBS'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 254 )
OLDLIBS="$( cd "${OLDLIBS}" && pwd -P )"

# Looking for needed libraries folders.
NEWFP="${NEWLIBS}/footprints"
[ -d "${NEWFP}" -a -r "${NEWFP}" ] || \
( echo "New footprints folder not found or not readable: '${NEWFP}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 253 )
OLDFP="${OLDLIBS}/footprints"
[ -d "${OLDFP}" -a -r "${OLDFP}" ] || \
( echo "Old footprints folder not found or not readable: '${OLDFP}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 253 )

# Looking for needed KiCAD library utilities in UTILS folder.
FPKLCK="${UTILS}/klc-check/check_footprint.py"
[ -r "${FPKLCK}" -a -x "${FPKLCK}" ] || \
( echo "Script not found or not executable: '${FPKLCK}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 252 )
TABKLCK="${UTILS}/klc-check/check_lib_table.py"
[ -r "${TABKLCK}" -a -x "${TABKLCK}" ] || \
( echo "Script not found or not executable: '${TABKLCK}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 252 )

# Disable fast exit for the main process phase.
set +e

#
# Execute the selected KLC checks, either compare or complete check.
#

echo "Print check-up logging output to: '${SCRIPT_LOG}'" \
| "${TEE}" -a "${SCRIPT_LOG}"
echo "Print check-up metrics output to: '${METRICS_TXT}'" \
| "${TEE}" -a "${SCRIPT_LOG}"
echo "Found KiCAD library utilities in: '${UTILS}'" \
| "${TEE}" -a "${SCRIPT_LOG}"

if [ "${NEWLIBS}" != "${OLDLIBS}" ]; then

  echo "Use new libraries in: '${NEWLIBS}'" \
  | "${TEE}" -a "${SCRIPT_LOG}"
  echo "Use old libraries in: '${OLDLIBS}'" \
  | "${TEE}" -a "${SCRIPT_LOG}"

  echo "Compared KLC check-up not (yet) supported." \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2
  exit 251

else

  declare -i +x FP_WARNING_CNT=0
  declare -i +x FP_ERROR_CNT=0
  declare -i +x TAB_ERROR_CNT=0

  declare -a +x FPLIBS_L=("${NEWFP}"/*.pretty/*.kicad_mod)
  declare -i +x FPLIBS_N=${#FPLIBS_L[@]}

  echo "Use libraries in: '${NEWLIBS}'" \
  | "${TEE}" -a "${SCRIPT_LOG}"

  if [ ${FPLIBS_N} -gt 0 ]; then

    echo "Found ${FPLIBS_N} libraries with footprints." \
    | "${TEE}" -a "${SCRIPT_LOG}"

    # Check all components in all footprint libraries.
    "${FPKLCK}" -vv -m $(printf "%q " "${FPLIBS_L[@]}") \
    | "${TEE}" -a "${SCRIPT_LOG}"
    FP_WARNING_CNT=$( "${AWK}" -e "${AWK_WARNINGS}" "${METRICS_TXT}" )
    echo "FootprintsWarningCount ${FP_WARNING_CNT}" >> "${METRICS_TXT}"
    FP_ERROR_CNT=$( "${AWK}" -e "${AWK_ERRORS}" "${METRICS_TXT}" )
    echo "FootprintsErrorCount ${FP_ERROR_CNT}" >> "${METRICS_TXT}"

    ERROR_CNT+=${FP_ERROR_CNT}

    # Compare the footprints table file against all footprint library files.
    "${TABKLCK}" --table "${NEWFP}"/fp-lib-table \
                         "${NEWFP}"/*.pretty \
    | "${TEE}" -a "${SCRIPT_LOG}"
    TAB_ERROR_CNT=${PIPESTATUS[0]}
    echo "FootprintsLibTableErrorCount ${TAB_ERROR_CNT}" >> "${METRICS_TXT}"

    ERROR_CNT+=${TAB_ERROR_CNT}

  else

    echo "No footprint libraries found, skip check-up." \
    | "${TEE}" -a "${SCRIPT_LOG}" >&2

  fi

fi

#
# Final data and result code clean-up.
#

echo "FootprintsTotalErrorCount ${ERROR_CNT}" >> "${METRICS_TXT}"

echo "Move check-up metrics output to: '${METRICS_FOOTPRINTS_TXT}'" \
| "${TEE}" -a "${SCRIPT_LOG}"
"${MOV}" -vf "${METRICS_TXT}" "${METRICS_FOOTPRINTS_TXT}" \
| "${TEE}" -a "${SCRIPT_LOG}"

[ ${ERROR_CNT} -gt ${ERROR_MAX} ] && ERROR_CNT=${ERROR_MAX}
exit ${ERROR_CNT}

# ############################################################################
# vim: ft=bash ts=2 sw=2 et ai:
