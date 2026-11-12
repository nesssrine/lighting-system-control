#!/bin/bash
# Installe la version finale (obstacle + contournement) et lance la demonstration
source /opt/ros/lyrical/setup.bash
D="$(cd "$(dirname "$0")" && pwd)"
export LSC_RESULTS="$D/results"
rm -rf ~/ros2_ws/src/lsc_ecu ~/ros2_ws/src/lsc_virtual
cp -r "$D/ros2_pkgs/lsc_ecu" "$D/ros2_pkgs/lsc_virtual" ~/ros2_ws/src/
cd ~/ros2_ws && colcon build --packages-select lsc_ecu lsc_virtual || exit 1
source install/local_setup.bash
ros2 launch lsc_virtual lsc_demo_launch.py 2>&1 | tee "$D/results/launch.txt"
