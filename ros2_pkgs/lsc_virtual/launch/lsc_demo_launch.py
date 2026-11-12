"""Demonstration complete : route avec virages, tunnel, ESS, nuit, voitures en face, maison + follow-me-home.

    ros2 launch lsc_virtual lsc_demo_launch.py            (demonstration automatique + 15 tests)
    ros2 launch lsc_virtual lsc_demo_launch.py auto:=false (route libre, commandes a la main)
"""
import os
import launch
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.conditions import IfCondition
from launch.substitutions import LaunchConfiguration
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
from webots_ros2_driver.webots_launcher import WebotsLauncher
from webots_ros2_driver.webots_controller import WebotsController


def generate_launch_description():
    pkg = get_package_share_directory('lsc_virtual')
    webots = WebotsLauncher(world=os.path.join(pkg, 'worlds', 'lsc_demo.wbt'), ros2_supervisor=True)
    car = WebotsController(robot_name='vehicle', respawn=True,
                           parameters=[{'robot_description': os.path.join(pkg, 'resource', 'lsc_car_demo.urdf')}])
    hud = WebotsController(robot_name='lsc_ambiance',
                           parameters=[{'robot_description': os.path.join(pkg, 'resource', 'lsc_hud.urdf')}])
    ecu = Node(package='lsc_ecu', executable='lsc_ecu_node', output='screen')
    demo = Node(package='lsc_virtual', executable='demo', output='screen', condition=IfCondition(LaunchConfiguration('auto')))
    return LaunchDescription([
        DeclareLaunchArgument('auto', default_value='true', description='true : demonstration automatique + verification'),
        webots, webots._supervisor, car, hud, ecu, demo,
        launch.actions.RegisterEventHandler(event_handler=launch.event_handlers.OnProcessExit(
            target_action=webots, on_exit=[launch.actions.EmitEvent(event=launch.events.Shutdown())])),
    ])
