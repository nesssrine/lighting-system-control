# Vehicule virtuel LSC (Webots + ROS 2 Lyrical)

## Construire (une seule fois, dans Ubuntu)
    cp -r <chemin_du_projet>/ros2_pkgs/lsc_ecu <chemin_du_projet>/ros2_pkgs/lsc_virtual ~/ros2_ws/src/
    cd ~/ros2_ws && colcon build --packages-select lsc_ecu lsc_virtual && source install/local_setup.bash

## Lancer
Terminal 1 (trajet complet jour, tunnel, nuit) :  ros2 launch lsc_virtual lsc_launch.py
Terminal 1 (trajet complet + TOUS les tests automatiques) :  ros2 launch lsc_virtual lsc_launch.py scenario:=true
Terminal 1 (jour + tunnel seul) :  ros2 launch lsc_virtual lsc_launch.py world:=lsc_jour_tunnel.wbt
Terminal 1 (nuit + AHB)    :  ros2 launch lsc_virtual lsc_launch.py world:=lsc_nuit.wbt
Terminal 2 (tableau de bord) : ros2 run lsc_virtual dashboard

## Commandes du conducteur (terminal 3)
    ros2 topic pub --once /lsc/cmd/turn_left std_msgs/msg/Bool "{data: true}"
    ros2 topic pub --once /lsc/cmd/hazard std_msgs/msg/Bool "{data: true}"
    ros2 topic pub --once /lsc/cmd/vehicle std_msgs/msg/Bool "{data: true}"      (vehicule en face)
    ros2 topic pub --once /lsc/cmd/cam_fault std_msgs/msg/Bool "{data: true}"    (panne camera)
    ros2 topic pub --once /lsc/cmd/light_switch std_msgs/msg/Int32 "{data: 3}"   (0 OFF,1 AUTO,2 POSITION,3 CROISEMENT)
    ros2 topic pub --once /lsc/cmd/lamp_fail_right std_msgs/msg/Bool "{data: true}" (ampoule droite grillee)

## Apres l'essai : figure pour le rapport
    ros2 run lsc_virtual plot_log
