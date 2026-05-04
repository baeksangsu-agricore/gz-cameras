#!/bin/bash
set -euo pipefail

if [ $# -lt 1 ]; then
    echo "Usage: $0 <world_name> [extra gz sim args...]"
    echo "Example: $0 base"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORLD_NAME="$1"
shift

WORLD_FILE="${SCRIPT_DIR}/worlds/${WORLD_NAME}.sdf"

if [ ! -f "${WORLD_FILE}" ]; then
    echo "Error: world file not found: ${WORLD_FILE}"
    exit 1
fi

if ! command -v ros2 >/dev/null 2>&1; then
    echo "Error: ros2 not found. Source ROS 2 setup first:  source /opt/ros/<distro>/setup.bash"
    exit 1
fi

BRIDGE_TOPICS=(
    /clock@rosgraph_msgs/msg/Clock[gz.msgs.Clock
    /color_camera@sensor_msgs/msg/Image[gz.msgs.Image
    /color_camera/camera_info@sensor_msgs/msg/CameraInfo[gz.msgs.CameraInfo
    /depth_camera@sensor_msgs/msg/Image[gz.msgs.Image
    /depth_camera/camera_info@sensor_msgs/msg/CameraInfo[gz.msgs.CameraInfo
    /depth_camera/points@sensor_msgs/msg/PointCloud2[gz.msgs.PointCloudPacked
)

SIM_PID=
BRIDGE_PID=

cleanup() {
    trap - EXIT INT TERM
    [ -n "${BRIDGE_PID}" ] && kill "${BRIDGE_PID}" 2>/dev/null || true
    [ -n "${SIM_PID}" ] && kill "${SIM_PID}" 2>/dev/null || true
    wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

echo "[run.sh] launching gz sim: ${WORLD_FILE}"
gz sim -r "${WORLD_FILE}" "$@" &
SIM_PID=$!

echo "[run.sh] launching ros_gz_bridge"
ros2 run ros_gz_bridge parameter_bridge "${BRIDGE_TOPICS[@]}" &
BRIDGE_PID=$!

wait -n "${SIM_PID}" "${BRIDGE_PID}"
