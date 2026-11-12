"""Plugin Webots de la Tesla : interface entre le vehicule virtuel et le calculateur LSC.

- lit les capteurs du vehicule (capteur de lumiere, GPS, vitesse, camera) et les publie sur /lsc/in/*
- recoit les sorties du calculateur (/lsc/out/*) et allume les vrais feux de la voiture 3D
- recoit les commandes de conduite du lane_follower (/cmd_ackermann), comme la demo Tesla
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import math
import rclpy
from std_msgs.msg import Bool, Float64, UInt8MultiArray
from ackermann_msgs.msg import AckermannDrive

VEHICLE_WORDS = ('toyota', 'prius', 'tesla', 'bmw', 'citroen', 'lincoln', 'mercedes', 'range', 'car', 'vehicle', 'truck', 'bus')


class LscCarPlugin:
    def init(self, webots_node, properties):
        self.robot = webots_node.robot
        self.ts = int(self.robot.getBasicTimeStep())
        self.zone = [float(properties.get(k, d)) for k, d in
                     (('tunnelXMin', -150), ('tunnelXMax', -110), ('tunnelYMin', -413), ('tunnelYMax', -387))]
        self.light = self._dev('ambient_light')
        self.gps = self._dev('gps')
        self.cam = self._dev('camera', enable=False)
        if self.cam is not None and self.cam.hasRecognition():
            self.cam.recognitionEnable(self.ts)
        self.low_led = self._dev('low_beam_led', enable=False)
        self.high_led = self._dev('high_beam_led', enable=False)
        self.blink_led = [self._dev('blink_left_led', enable=False), self._dev('blink_right_led', enable=False)]
        cls = type(self.robot)
        self.IND_OFF = getattr(cls, 'INDICATOR_OFF', 0)
        self.IND_RIGHT = getattr(cls, 'INDICATOR_RIGHT', 1)
        self.IND_LEFT = getattr(cls, 'INDICATOR_LEFT', 2)

        if not rclpy.ok():
            rclpy.init(args=None)
        self.node = rclpy.create_node('lsc_car')
        self.node.declare_parameter('lux_gain', 1.0)      # correction eventuelle de la mesure du capteur
        self.node.declare_parameter('tunnel_lux', 150.0)  # eclairage artificiel du tunnel [lux]
        self.node.declare_parameter('speed', 50.0)        # vitesse de croisiere sur la piste [km/h]
        self.node.declare_parameter('lane_y', -402.7)     # voie de droite de la piste d'essai [m]
        self.node.declare_parameter('x_end', 1135.0)       # fin de la piste : arret [m]
        p = self.node.create_publisher
        self.pub = {k: p(Float64, '/lsc/in/' + k, 10) for k in ('lux', 'speed', 'decel')}
        self.pub_veh = p(Bool, '/lsc/in/vehicle_detected', 10)
        self.pub_cam = p(Bool, '/lsc/in/cam_ok', 10)
        self.pub_tunnel = p(Bool, '/lsc/in/in_tunnel', 10)
        self.pub_x = p(Float64, '/lsc/in/x', 10)
        self.target = None
        self.stop = False
        self.node.create_subscription(Float64, '/lsc/cmd/target_speed', lambda m: setattr(self, 'target', m.data), 10)
        self.node.create_subscription(Bool, '/lsc/cmd/stop', lambda m: setattr(self, 'stop', m.data), 10)
        self.node.create_subscription(AckermannDrive, 'cmd_ackermann', self._on_drive, 1)
        self.node.create_subscription(UInt8MultiArray, '/lsc/out/duty', self._on_duty, 10)
        self.node.create_subscription(Bool, '/lsc/out/hazard', self._on_hazard, 10)
        self.duty = [0] * 8
        self.hazard = False
        self.last_blink = [-10.0, -10.0]
        self.prev_speed = 0.0
        self.decel = 0.0
        self.applied = None
        self.node.get_logger().info('Vehicule virtuel LSC pret (capteur de lumiere, GPS, camera, feux)')

    def _dev(self, name, enable=True):
        try:
            d = self.robot.getDevice(name)
        except Exception:
            d = None
        if d is not None and enable:
            d.enable(self.ts)
        return d

    # ----- commandes recues
    def _on_drive(self, m):
        pass    # le guidage est fait par GPS sur la piste d'essai (voir _drive)

    def _drive(self):
        """Guidage simple sur la piste rectiligne : vitesse constante, maintien dans la voie par GPS."""
        if self.gps is None:
            return
        x, y, _ = self.gps.getValues()
        vy = self.gps.getSpeedVector()[1] if hasattr(self.gps, 'getSpeedVector') else 0.0
        vx = max(abs(self.gps.getSpeed()), 1.0) if hasattr(self.gps, 'getSpeed') else 10.0
        if any(math.isnan(c) for c in (x, y, vy)):
            return
        self.pub_x.publish(Float64(data=float(x)))
        if self.stop or x > self.node.get_parameter('x_end').value:
            self.robot.setCruisingSpeed(0.0)
            self.robot.setBrakeIntensity(1.0)
            self.robot.setSteeringAngle(0.0)
            return
        err = y - self.node.get_parameter('lane_y').value       # > 0 : la voiture est a gauche de sa voie
        steer = 0.02 * err + 0.5 * vy / vx                       # angle > 0 : braquage a droite
        self.robot.setSteeringAngle(max(-0.12, min(0.12, steer)))
        self.robot.setBrakeIntensity(0.0)
        self.robot.setCruisingSpeed(self.target if self.target is not None else self.node.get_parameter('speed').value)

    def _on_duty(self, m):
        self.duty = list(m.data)

    def _on_hazard(self, m):
        self.hazard = m.data

    # ----- capteurs
    def _in_tunnel(self):
        if self.gps is None:
            return False
        x, y, _ = self.gps.getValues()
        return self.zone[0] <= x <= self.zone[1] and self.zone[2] <= y <= self.zone[3]

    def _vehicle_ahead(self):
        if self.cam is None or not self.cam.hasRecognition():
            return False
        for o in self.cam.getRecognitionObjects():
            model = (o.getModel() or '').lower()
            pos = o.getPosition()
            dist = math.sqrt(pos[0] ** 2 + pos[1] ** 2 + pos[2] ** 2)
            if any(w in model for w in VEHICLE_WORDS) and dist < 90:
                return True
        return False

    def step(self):
        rclpy.spin_once(self.node, timeout_sec=0)
        self._drive()
        t = self.robot.getTime()
        dt = self.ts / 1000.0
        gain = self.node.get_parameter('lux_gain').value
        lux = gain * self.light.getValue() if self.light is not None else 20000.0
        tunnel = self._in_tunnel()
        if tunnel:                                   # sous le tunnel : seul l'eclairage artificiel compte
            lux = min(lux, self.node.get_parameter('tunnel_lux').value)
        v = self.gps.getSpeed() * 3.6 if self.gps is not None else 0.0   # vitesse mesuree par GPS [km/h]
        v = 0.0 if v is None or math.isnan(v) else v
        a = -(v - self.prev_speed) / 3.6 / dt                           # deceleration m/s2
        self.decel += 0.05 * (a - self.decel)
        self.prev_speed = v
        for k, val in (('lux', lux), ('speed', v), ('decel', max(self.decel, 0.0))):
            self.pub[k].publish(Float64(data=float(val)))
        self.pub_veh.publish(Bool(data=self._vehicle_ahead()))
        self.pub_cam.publish(Bool(data=self.cam is not None))
        self.pub_tunnel.publish(Bool(data=tunnel))
        self._apply(t)

    # ----- sorties du calculateur -> feux de la voiture 3D
    def _apply(self, t):
        d = self.duty
        low = d[0] > 0 or d[1] > 0
        high = d[2] > 0
        fog = d[7] > 0
        blink = (d[4] > 0, d[5] > 0)          # phase allumee/eteinte calculee par B5 (clignotant, detresse, hyper)
        state = (low, high, fog, blink)
        if state == self.applied:
            return
        self.applied = state
        for f, v in ((self.robot.setDippedBeams, low), (self.robot.setAntifogLights, fog)):
            try:
                f(v)
            except Exception:
                pass
        if self.low_led is not None:
            self.low_led.set(1 if low else 0)
        if self.high_led is not None:
            self.high_led.set(1 if high else 0)
        for led, on in zip(self.blink_led, blink):
            if led is not None:
                led.set(1 if on else 0)
