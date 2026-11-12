"""Suivi de voie de la Tesla (adapte de la demo webots_ros2_tesla, Apache 2.0, Cyberbotics).
Modifications LSC : vitesse reglable (45 km/h par defaut), braquage conserve quand la ligne jaune
n'est plus visible (tunnel, eblouissement), braquage limite et lisse."""
import cv2
import numpy as np
import rclpy
from rclpy.node import Node
from rclpy.qos import qos_profile_sensor_data, QoSReliabilityPolicy
from sensor_msgs.msg import Image
from ackermann_msgs.msg import AckermannDrive

K = 0.0005


class LaneFollower(Node):
    def __init__(self):
        super().__init__('lsc_lane_follower')
        self.declare_parameter('speed', 45.0)
        self.pub = self.create_publisher(AckermannDrive, 'cmd_ackermann', 1)
        qos = qos_profile_sensor_data
        qos.reliability = QoSReliabilityPolicy.RELIABLE
        self.create_subscription(Image, 'vehicle/camera/image_color', self.on_image, qos)
        self.steer = 0.0
        self.lost = 0

    def on_image(self, m):
        img = np.frombuffer(m.data, dtype=np.uint8).reshape((m.height, m.width, 4))[160:190, :]
        hsv = cv2.cvtColor(cv2.cvtColor(img, cv2.COLOR_RGBA2RGB), cv2.COLOR_RGB2HSV)
        mask = cv2.inRange(hsv, np.array([50, 110, 150]), np.array([120, 255, 255]))
        contours, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
        target = None
        if contours:
            c = max(contours, key=cv2.contourArea)
            mo = cv2.moments(c)
            if mo['m00'] > 15:
                target = float(np.clip((mo['m10'] / mo['m00'] - 190) * K, -0.25, 0.25))
        if target is None:
            self.lost += 1          # ligne invisible : on garde le dernier braquage
        else:
            self.lost = 0
            self.steer += 0.5 * (target - self.steer)
        cmd = AckermannDrive()
        cmd.speed = float(self.get_parameter('speed').value)
        cmd.steering_angle = self.steer
        self.pub.publish(cmd)


def main():
    rclpy.init()
    rclpy.spin(LaneFollower())
