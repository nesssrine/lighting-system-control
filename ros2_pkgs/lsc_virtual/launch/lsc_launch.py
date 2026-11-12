"""Lance le vehicule virtuel : Webots (Windows) + Tesla + calculateur LSC (code C) + suivi de voie."""
import os
import launch
from launch import LaunchDescription
from launch.actions import DeclareLaunchArgument
from launch.substitutions import LaunchConfiguration, PythonExpression
from launch.conditions import IfCondition
from launch.substitutions.path_join_substitution import PathJoinSubstitution
from launch_ros.actions import Node
from ament_index_python.packages import get_package_share_directory
from webots_ros2_driver.webots_launcher import WebotsLauncher
from webots_ros2_driver.webots_controller import WebotsController


def generate_launch_description():
    pkg = get_package_share_directory('lsc_virtual')
    webots = WebotsLauncher(world=PathJoinSubstitution([pkg, 'worlds', LaunchConfiguration('world')]), ros2_supervisor=True)
    car = WebotsController(robot_name='vehicle',
                           parameters=[{'robot_description': os.path.join(pkg, 'resource', 'lsc_car.urdf')}],
                           respawn=True)
    ambiance = WebotsController(robot_name='lsc_ambiance',
                                parameters=[{'robot_description': os.path.join(pkg, 'resource', 'lsc_ambiance.urdf')}])
    scenario = Node(package='lsc_virtual', executable='scenario', output='screen',
                    condition=IfCondition(LaunchConfiguration('scenario')))
    ecu = Node(package='lsc_ecu', executable='lsc_ecu_node', output='screen')
    return LaunchDescription([
        DeclareLaunchArgument('scenario', default_value='false',
                              description='true : joue automatiquement tous les cas du cahier des charges'),
        DeclareLaunchArgument('world', default_value='lsc_trajet_complet.wbt',
                              description='lsc_trajet_complet.wbt (jour, tunnel, crepuscule, nuit), lsc_jour_tunnel.wbt ou lsc_nuit.wbt'),
        webots, webots._supervisor, car, ambiance, ecu, scenario,
        launch.actions.RegisterEventHandler(event_handler=launch.event_handlers.OnProcessExit(
            target_action=webots, on_exit=[launch.actions.EmitEvent(event=launch.events.Shutdown())])),
    ])
