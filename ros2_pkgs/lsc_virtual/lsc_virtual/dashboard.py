"""Tableau de bord du calculateur LSC : affiche l'etat des feux en direct et enregistre un journal CSV."""
import os
import time
import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool, Float64, UInt8, UInt16, UInt8MultiArray

ETATS = ['OFF', 'DRL', 'POSITION', 'CROISEMENT', 'ROUTE', 'FOLLOW-ME-HOME']
AHB = ['OFF', 'PRET', 'ACTIF', 'PAUSE', 'DEFAUT']


class Dashboard(Node):
    def __init__(self):
        super().__init__('lsc_dashboard')
        self.v = dict(lux=0.0, lux_filt=0.0, speed=0.0, state=0, ahb=0, dtc=0, hazard=False, ess=False,
                      fmh=False, warning=False, veh=False, tunnel=False, duty=[0] * 8)
        sub = self.create_subscription
        sub(Float64, '/lsc/in/lux', lambda m: self.set('lux', m.data), 10)
        sub(Float64, '/lsc/in/speed', lambda m: self.set('speed', m.data), 10)
        sub(Bool, '/lsc/in/vehicle_detected', lambda m: self.set('veh', m.data), 10)
        sub(Bool, '/lsc/in/in_tunnel', lambda m: self.set('tunnel', m.data), 10)
        sub(Float64, '/lsc/out/lux_filt', lambda m: self.set('lux_filt', m.data), 10)
        sub(UInt8, '/lsc/out/light_state', lambda m: self.set('state', m.data), 10)
        sub(UInt8, '/lsc/out/ahb_state', lambda m: self.set('ahb', m.data), 10)
        sub(UInt16, '/lsc/out/dtc', lambda m: self.set('dtc', m.data), 10)
        sub(Bool, '/lsc/out/hazard', lambda m: self.set('hazard', m.data), 10)
        sub(Bool, '/lsc/out/ess', lambda m: self.set('ess', m.data), 10)
        sub(Bool, '/lsc/out/fmh', lambda m: self.set('fmh', m.data), 10)
        sub(Bool, '/lsc/out/warning', lambda m: self.set('warning', m.data), 10)
        sub(UInt8MultiArray, '/lsc/out/duty', lambda m: self.set('duty', list(m.data)), 10)
        self.t0 = time.time()
        path = os.path.expanduser('~/lsc_log.csv')
        self.log = open(path, 'w')
        self.log.write('t,lux,lux_filt,speed,tunnel,vehicle,light_state,ahb_state,duty_low_L,duty_low_R,duty_high,'
                       'duty_blink_L,duty_blink_R,hazard,dtc\n')
        self.create_timer(0.1, self.record)
        self.create_timer(0.5, self.show)
        self.get_logger().info('Journal enregistre dans ' + path)

    def set(self, k, val):
        self.v[k] = val

    def record(self):
        v = self.v; d = v['duty']
        self.log.write('%.2f,%.1f,%.1f,%.1f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n' % (
            time.time() - self.t0, v['lux'], v['lux_filt'], v['speed'], v['tunnel'], v['veh'], v['state'], v['ahb'],
            d[0], d[1], d[2], d[4], d[5], v['hazard'], v['dtc']))
        self.log.flush()

    def show(self):
        v = self.v; d = v['duty']
        print('t=%6.1f s | %5.0f km/h | lux %7.0f (filtre %7.0f)%s | FEUX %-14s | croisement %3d%% | route %3d%% | '
              'AHB %-6s%s%s | DTC %d' % (
                  time.time() - self.t0, v['speed'], v['lux'], v['lux_filt'], ' TUNNEL' if v['tunnel'] else '',
                  ETATS[min(v['state'], 5)], d[0], d[2], AHB[min(v['ahb'], 4)],
                  ' vehicule en face' if v['veh'] else '', ' DETRESSE' if v['hazard'] else '', v['dtc']), flush=True)


def main():
    rclpy.init()
    rclpy.spin(Dashboard())
