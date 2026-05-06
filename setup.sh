#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

PX4_DIR="${HOME}/PX4-Autopilot"
if [ ! -d "${PX4_DIR}" ]; then
    echo "PX4-Autopilot not found at default location: ${PX4_DIR}"
    read -r -p "Enter PX4-Autopilot path: " PX4_DIR
    PX4_DIR="${PX4_DIR/#\~/${HOME}}"
    if [ ! -d "${PX4_DIR}" ]; then
        echo "Error: directory does not exist: ${PX4_DIR}"
        exit 1
    fi
fi

GZ_DIR="${PX4_DIR}/Tools/simulation/gz"
AIRFRAMES_DIR="${PX4_DIR}/ROMFS/px4fmu_common/init.d-posix/airframes"
CMAKE_LIST="${AIRFRAMES_DIR}/CMakeLists.txt"

if [ ! -d "${GZ_DIR}/models" ]; then
    echo "Error: PX4 gz simulation folders not found under: ${GZ_DIR}"
    exit 1
fi
if [ ! -f "${CMAKE_LIST}" ]; then
    echo "Error: PX4 airframes CMakeLists.txt not found at: ${CMAKE_LIST}"
    exit 1
fi

echo "[setup.sh] PX4-Autopilot: ${PX4_DIR}"

echo "[setup.sh] copying models -> ${GZ_DIR}/models"
cp -rv "${SCRIPT_DIR}/models/." "${GZ_DIR}/models/"

if [ -d "${SCRIPT_DIR}/airframes" ]; then
    echo "[setup.sh] copying airframes -> ${AIRFRAMES_DIR}"
    cp -rv "${SCRIPT_DIR}/airframes/." "${AIRFRAMES_DIR}/"

    for af in "${SCRIPT_DIR}/airframes"/*; do
        [ -f "${af}" ] || continue
        name="$(basename "${af}")"
        if grep -qE "^[[:space:]]+${name}[[:space:]]*$" "${CMAKE_LIST}"; then
            echo "[setup.sh] CMakeLists.txt already lists ${name}; skipping"
        else
            echo "[setup.sh] adding ${name} to CMakeLists.txt"
            awk -v name="${name}" '
                BEGIN { added = 0 }
                /^\)/ && !added { print "\t" name; added = 1 }
                { print }
            ' "${CMAKE_LIST}" > "${CMAKE_LIST}.tmp"
            mv "${CMAKE_LIST}.tmp" "${CMAKE_LIST}"
        fi
    done
fi

echo "[setup.sh] building PX4 SITL ('make px4_sitl')"
(cd "${PX4_DIR}" && make px4_sitl)

echo "[setup.sh] done."
