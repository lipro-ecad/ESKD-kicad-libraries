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
METRICS_3DMODELS_TXT="${METRICS_TXT%.*}_3dmodels.txt"

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
AWK_ERRORS='/^.*-[[:blank:]]*Mislabeled.*$/ {errors++} END {print errors}'
LNK="$( type -P "ln" )" || ( \
        echo "Executable not found: 'ln'" >&2 ; exit 255 )
DEL="$( type -P "rm" )" || ( \
        echo "Executable not found: 'rm'" >&2 ; exit 255 )
MOV="$( type -P "mv" )" || ( \
        echo "Executable not found: 'mv'" >&2 ; exit 255 )

# Make sure the logging output file is writable.
"${TCH}" -m "${SCRIPT_LOG}"
:> "${SCRIPT_LOG}"

# Make sure the metrics output file is writable.
"${TCH}" -m "${METRICS_3DMODELS_TXT}"
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

# Looking for needed libraries folders.
NEWFP="${NEWLIBS}/footprints"
[ -d "${NEWFP}" -a -w "${NEWFP}" ] || \
( echo "Footprints folder not found or not writable: '${NEWFP}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 253 )
NEW3D="${NEWLIBS}/3dmodels"
[ -d "${NEW3D}" -a -r "${NEW3D}" ] || \
( echo "3D models folder not found or not readable: '${NEW3D}'" \
  | "${TEE}" -a "${SCRIPT_LOG}" >&2 ; exit 253 )

# Looking for needed KiCAD library utilities in UTILS folder.
M3DKLCK="${UTILS}/packages3d/check_3dmodels.py"
[ -r "${M3DKLCK}" -a -r "${M3DKLCK}" ] || \
( echo "Script not found or not readable: '${M3DKLCK}'" \
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

{

  declare -i +x M3D_ERROR_CNT=0
  declare -i +x CHK_ERROR_CNT=0

  declare -a +x PTLIBS_L=("${NEWFP}"/*.pretty)
  declare -i +x PTLIBS_N=${#PTLIBS_L[@]}

  declare -a +x SHLIBS_L=("${NEW3D}"/*.3dshapes)
  declare -i +x SHLIBS_N=${#SHLIBS_L[@]}

  echo "Use libraries in: '${NEWLIBS}'" \
  | "${TEE}" -a "${SCRIPT_LOG}"

  if [ ${PTLIBS_N} -gt 0 -a ${SHLIBS_N} -gt 0 ]; then

    echo "Found ${PTLIBS_N} libraries with footprints." \
    | "${TEE}" -a "${SCRIPT_LOG}"
    echo "Found ${SHLIBS_N} libraries with 3D models." \
    | "${TEE}" -a "${SCRIPT_LOG}"

    # Check all 3D models references in all footprint libraries.
    "${PY3}" "${M3DKLCK}" -v --pretty $(printf "%q " "${PTLIBS_L[@]}") \
                             --models $(printf "%q " "${SHLIBS_L[@]}") \
    | "${TEE}" -a "${SCRIPT_LOG}"

    CHK_ERROR_CNT=${PIPESTATUS[0]}
    # exit code invalid (overrun 255): ERROR_CNT+=${CHK_ERROR_CNT}

    M3D_ERROR_CNT=$( "${AWK}" -e "${AWK_ERRORS}" "${SCRIPT_LOG}" )
    echo "3DModelsErrorCount ${M3D_ERROR_CNT}" >> "${METRICS_TXT}"

    ERROR_CNT+=${M3D_ERROR_CNT}

  else

    echo "No footprint or 3D model libraries found, skip check-up." \
    | "${TEE}" -a "${SCRIPT_LOG}" >&2

  fi

}

#
# Final data and result code clean-up.
#

echo "3DModelsTotalErrorCount ${ERROR_CNT}" >> "${METRICS_TXT}"

echo "Move check-up metrics output to: '${METRICS_3DMODELS_TXT}'" \
| "${TEE}" -a "${SCRIPT_LOG}"
"${MOV}" -vf "${METRICS_TXT}" "${METRICS_3DMODELS_TXT}" \
| "${TEE}" -a "${SCRIPT_LOG}"

[ ${ERROR_CNT} -gt ${ERROR_MAX} ] && ERROR_CNT=${ERROR_MAX}
exit ${ERROR_CNT}

# ############################################################################
# vim: ft=bash ts=2 sw=2 et ai:
