"""Plugin Webots de la Tesla - DEMONSTRATION : route avec virages, tunnel, maison.

- guidage automatique le long de la route (poursuite de trajectoire, GPS + centrale inertielle)
- lit les capteurs (lumiere, vitesse, camera) -> /lsc/in/*
- applique les sorties du calculateur (/lsc/out/*) aux feux 3D : DRL, croisement, route,
  clignotants avant/arriere, feux arriere (position / stop / ESS)
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import math
import rclpy
from std_msgs.msg import Bool, Float64, Int32, UInt8MultiArray

VEHICLE_WORDS = ('toyota', 'prius', 'tesla', 'bmw', 'citroen', 'lincoln', 'mercedes', 'range', 'car', 'vehicle', 'truck', 'bus')
LANE = 2.0          # voie de droite : 2 m a droite de l'axe de la route
WHEELBASE = 2.94


def build_path():
    """Axe de la route (un point par metre) : (x, y, cap)."""
    P = []
    def line(x, y, h, L):
        for i in range(int(L)):
            P.append((x + i * math.cos(h), y + i * math.sin(h), h))
    def arc(cx, cy, R, a0, a1, cw):
        n = int(abs(a1 - a0) * R)
        for i in range(n):
            a = a0 + (a1 - a0) * i / n
            P.append((cx + R * math.cos(a), cy + R * math.sin(a), a - math.pi / 2 if cw else a + math.pi / 2))
    line(-700, -600, 0.0, 200)                                         # route A vers l'est
    arc(-500, -640, 40, math.pi / 2, 0.0, True)                        # virage a droite
    line(-460, -640, -math.pi / 2, 150)                                # route B vers le sud (tunnel)
    arc(-420, -790, 40, math.pi, 1.5 * math.pi, False)                 # virage a gauche
    line(-420, -830, 0.0, 916)                                         # route C vers l'est, jusqu'a la maison
    return [(x + LANE * math.sin(h), y - LANE * math.cos(h), h) for x, y, h in P]


class LscDemoPlugin:
    def init(self, webots_node, properties):
        self.robot = webots_node.robot
        self.ts = int(self.robot.getBasicTimeStep())
        dev = self._dev
        self.light, self.gps, self.imu = dev('ambient_light'), dev('gps'), dev('imu')
        self.cam = dev('camera', enable=False)
        if self.cam is not None:
            self.cam.enable(64)
            if self.cam.hasRecognition():
                self.cam.recognitionEnable(64)
        names = ('low_beam_led', 'high_beam_led', 'drl_left_led', 'drl_right_led', 'blink_front_left_led', 'blink_front_right_led',
                 'rear_left_led', 'rear_right_led', 'blink_rear_left_led', 'blink_rear_right_led')
        self.led = {n: dev(n, enable=False) for n in names}
        self.path = build_path()
        self.idx = 0
        self.zone = (-466.0, -454.0, -740.0, -680.0)        # tunnel (route B)
        if not rclpy.ok():
            rclpy.init(args=None)
        self.node = rclpy.create_node('lsc_car')
        self.node.declare_parameter('tunnel_lux', 150.0)
        p = self.node.create_publisher
        self.pub = {k: p(Float64, '/lsc/in/' + k, 10) for k in ('lux', 'speed', 'decel', 'x', 's')}
        self.pub_veh = p(Bool, '/lsc/in/vehicle_detected', 10)
        self.pub_cam = p(Bool, '/lsc/in/cam_ok', 10)
        self.pub_tunnel = p(Bool, '/lsc/in/in_tunnel', 10)
        sub = self.node.create_subscription
        self.duty, self.hazard, self.lamp_mask = [0] * 8, False, 0
        self.target, self.brake_level, self.ess_stop = 50.0, 0.0, False
        sub(UInt8MultiArray, '/lsc/out/duty', lambda m: setattr(self, 'duty', list(m.data)), 10)
        sub(Bool, '/lsc/out/hazard', lambda m: setattr(self, 'hazard', m.data), 10)
        sub(Int32, '/lsc/cmd/lamp_fail', lambda m: setattr(self, 'lamp_mask', m.data), 10)
        sub(Float64, '/lsc/cmd/target_speed', lambda m: setattr(self, 'target', m.data), 10)
        sub(Float64, '/lsc/cmd/brake_level', lambda m: setattr(self, 'brake_level', m.data), 10)
        sub(Bool, '/lsc/cmd/stop', lambda m: setattr(self, 'ess_stop', m.data), 10)
        self.off, self.off_target = 0.0, 0.0                  # decalage lateral vers la gauche (contournement) [m]
        sub(Float64, '/lsc/cmd/lane_offset', lambda m: setattr(self, 'off_target', m.data), 10)
        self.prev_v, self.decel, self.applied = 0.0, 0.0, None
        self.node.get_logger().info('Tesla de demonstration prete (%d points de trajectoire)' % len(self.path))

    def _dev(self, name, enable=True):
        try:
            d = self.robot.getDevice(name)
        except Exception:
            d = None
        if d is not None and enable:
            d.enable(self.ts)
        return d

    # ---------- conduite automatique
    def _drive(self, x, y, yaw, v):
        n = len(self.path)
        lo, hi = max(0, self.idx - 5), min(n, self.idx + 40)
        self.idx = min(range(lo, hi), key=lambda i: (self.path[i][0] - x) ** 2 + (self.path[i][1] - y) ** 2)
        s = float(self.idx)
        ld = max(7.0, 0.6 * v / 3.6 + 4.0)
        tx, ty, th = self.path[min(n - 1, self.idx + int(ld))]
        step = 1.5 * self.ts / 1000.0                                   # changement de voie a 1,5 m/s lateral
        self.off += max(-step, min(step, self.off_target - self.off))
        tx, ty = tx - self.off * math.sin(th), ty + self.off * math.cos(th)   # point vise decale vers la gauche
        alpha = math.atan2(ty - y, tx - x) - yaw
        alpha = math.atan2(math.sin(alpha), math.cos(alpha))
        delta = math.atan2(2 * WHEELBASE * math.sin(alpha), ld)
        self.robot.setSteeringAngle(max(-0.5, min(0.5, -delta)))     # angle Webots > 0 : a droite
        if self.ess_stop:
            self.robot.setCruisingSpeed(0.0); self.robot.setBrakeIntensity(1.0)
        elif self.brake_level > 0 or self.idx >= n - 3:
            self.robot.setCruisingSpeed(0.0); self.robot.setBrakeIntensity(max(self.brake_level, 0.6))
        else:
            self.robot.setBrakeIntensity(0.0); self.robot.setCruisingSpeed(self.target)
        return s

    def _vehicle_ahead(self):
        if self.cam is None or not self.cam.hasRecognition():
            return False
        for o in self.cam.getRecognitionObjects():
            model = (o.getModel() or '').lower()
            p = o.getPosition()
            if any(w in model for w in VEHICLE_WORDS) and math.sqrt(p[0] ** 2 + p[1] ** 2 + p[2] ** 2) < 90:
                return True
        return False

    def step(self):
        rclpy.spin_once(self.node, timeout_sec=0)
        if self.gps is None or self.imu is None:
            return
        x, y, _ = self.gps.getValues()
        if any(math.isnan(c) for c in (x, y)):
            return
        yaw = self.imu.getRollPitchYaw()[2]
        v = self.gps.getSpeed() * 3.6
        v = 0.0 if math.isnan(v) else v
        s = self._drive(x, y, yaw, v)
        dt = self.ts / 1000.0
        self.decel += 0.05 * (-(v - self.prev_v) / 3.6 / dt - self.decel)
        self.prev_v = v
        lux = self.light.getValue() if self.light is not None else 20000.0
        z = self.zone
        tunnel = z[0] <= x <= z[1] and z[2] <= y <= z[3]
        if tunnel:
            lux = min(lux, self.node.get_parameter('tunnel_lux').value)
        for k, val in (('lux', lux), ('speed', v), ('decel', max(self.decel, 0.0)), ('x', x), ('s', s)):
            self.pub[k].publish(Float64(data=float(val)))
        self.pub_veh.publish(Bool(data=self._vehicle_ahead()))
        self.pub_cam.publish(Bool(data=self.cam is not None))
        self.pub_tunnel.publish(Bool(data=tunnel))
        self._apply()

    # ---------- sorties du calculateur -> feux 3D
    def _set(self, name, value):
        d = self.led.get(name)
        if d is not None:
            d.set(int(value))

    def _apply(self):
        d = self.duty
        low, high = d[0] > 0 or d[1] > 0, d[2] > 0
        bl, br = d[4] > 0, d[5] > 0
        state = (low, high, d[3], bl, br, d[6], self.lamp_mask)
        if state == self.applied:
            return
        self.applied = state
        try:
            self.robot.setDippedBeams(low)
        except Exception:
            pass
        self._set('low_beam_led', 1 if low else 0)
        self._set('high_beam_led', 1 if high else 0)
        drl = int(d[3] * 2.55)                                   # LED avant : DRL 100 % / veilleuse 30 %
        self._set('drl_left_led', drl); self._set('drl_right_led', drl)
        failed_left = bool(self.lamp_mask & 4)                    # ampoule clignotant avant gauche grillee
        self._set('blink_front_left_led', 1 if bl and not failed_left else 0)
        self._set('blink_rear_left_led', 1 if bl else 0)
        self._set('blink_front_right_led', 1 if br else 0)
        self._set('blink_rear_right_led', 1 if br else 0)
        rear = int(d[6] * 2.55)                                  # feux arriere : position 20 % / stop 100 % / ESS clignotant
        self._set('rear_left_led', rear); self._set('rear_right_led', rear)
