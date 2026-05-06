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
if [ ! -d "${GZ_DIR}/models" ] || [ ! -d "${GZ_DIR}/worlds" ]; then
    echo "Error: PX4 gz simulation folders not found under: ${GZ_DIR}"
    exit 1
fi

echo "[setup.sh] PX4-Autopilot: ${PX4_DIR}"
echo "[setup.sh] copying models -> ${GZ_DIR}/models"
cp -rv "${SCRIPT_DIR}/models/." "${GZ_DIR}/models/"

echo "[setup.sh] copying worlds -> ${GZ_DIR}/worlds"
cp -rv "${SCRIPT_DIR}/worlds/." "${GZ_DIR}/worlds/"

echo "[setup.sh] done."
