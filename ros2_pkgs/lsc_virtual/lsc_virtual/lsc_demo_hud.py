"""Superviseur de la demonstration : tombee de la nuit + affichage (HUD) en haut de la vue 3D.

Le HUD montre en direct ce que decide le calculateur LSC : vitesse, phase du scenario, etat des feux,
clignotants / detresse / hyper-clignotement, ESS, luminosite, vehicule detecte, compte a rebours FMH.
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import math
import rclpy
from std_msgs.msg import Bool, Float64, String, UInt8, UInt16, UInt8MultiArray

X_DUSK, X_NIGHT, NIGHT = -70.0, 20.0, 0.0008           # crepuscule sur la route C [m], luminosite de nuit
ETATS = ['ETEINTS', 'FEUX DE JOUR (DRL)', 'POSITION', 'CROISEMENT', 'ROUTE', 'FOLLOW-ME-HOME']
AHB = ['OFF', 'PRET', 'ACTIF', 'PAUSE (vehicule / appel)', 'DEFAUT CAMERA']
WHITE, YELLOW, ORANGE, RED, GREEN, CYAN, BLACK = 0xFFFFFF, 0xFFD400, 0xFF8C00, 0xFF3030, 0x40FF60, 0x40D0FF, 0x000000


class LscDemoHud:
    def init(self, webots_node, properties):
        self.sv = webots_node.robot
        self.ego = self.sv.getFromDef('EGO')
        sun, sky, fog = (self.sv.getFromDef(n) for n in ('SUN', 'SKY', 'FOG'))
        self.ok = None not in (self.ego, sun, sky, fog)
        if self.ok:
            self.sun_i, self.sun_a = sun.getField('intensity'), sun.getField('ambientIntensity')
            self.sky = sky.getField('luminosity')
            self.fog_color, self.fog_range = fog.getField('color'), fog.getField('visibilityRange')
        self.f = None
        self.v = dict(speed=0.0, lux=0.0, tunnel=False, veh=False, state=0, ahb=0, duty=[0] * 8, hazard=False, ess=False,
                      fmh=False, dtc=0, phase='', detail='', vbat=14.2, soc=100.0)
        self.lbl = {}
        self.exit_t = None                     # instant ou le conducteur descend (porte ouverte)
        self.seat_hidden = False
        self.t_in = None
        self.parts = {n: self.sv.getFromDef(n) for n in ('D_BODY', 'D_LLEG', 'D_RLEG', 'D_LARM', 'D_RARM', 'HOUSE_DOOR', 'HOUSE_LIGHT')}
        self.k = 0
        # projecteurs de la Tesla (LED croisement et route du slot avant) : intensite selon la tension efficace
        self.spot = {}
        try:
            front = self.ego.getField('sensorsSlotFront')
            for key, idx, base in (('low', 2, 2.5), ('high', 3, 12.0)):
                f = front.getMFNode(idx).getField('children').getMFNode(0).getField('intensity')
                self.spot[key] = [f, base, None]
        except Exception:
            self.spot = {}
        self.rel = 1.0
        if not rclpy.ok():
            rclpy.init(args=None)
        self.node = rclpy.create_node('lsc_hud')
        s = self.node.create_subscription
        for k, typ, topic in (('speed', Float64, '/lsc/in/speed'), ('lux', Float64, '/lsc/in/lux'), ('tunnel', Bool, '/lsc/in/in_tunnel'),
                              ('veh', Bool, '/lsc/in/vehicle_detected'), ('state', UInt8, '/lsc/out/light_state'),
                              ('ahb', UInt8, '/lsc/out/ahb_state'), ('hazard', Bool, '/lsc/out/hazard'), ('ess', Bool, '/lsc/out/ess'),
                              ('fmh', Bool, '/lsc/out/fmh'), ('dtc', UInt16, '/lsc/out/dtc'), ('phase', String, '/lsc/phase'),
                              ('detail', String, '/lsc/phase_detail'), ('vbat', Float64, '/lsc/in/vbat'), ('soc', Float64, '/lsc/in/soc')):
            s(typ, topic, lambda m, k=k: self.v.__setitem__(k, m.data), 10)
        s(UInt8MultiArray, '/lsc/out/duty', lambda m: self.v.__setitem__('duty', list(m.data)), 10)
        s(Bool, '/lsc/cmd/door_closed', self._door, 10)

    def _door(self, m):
        if not m.data and self.exit_t is None:
            self.exit_t = self.sv.getTime()

    # ---------- le conducteur descend, marche dans le faisceau des phares et entre dans la maison
    def _put(self, name, x, y, z, angle=None, axis=(0, 1, 0)):
        n = self.parts.get(name)
        if n is None:
            return
        n.getField('translation').setSFVec3f([float(x), float(y), float(z)])
        if angle is not None:
            n.getField('rotation').setSFRotation([float(axis[0]), float(axis[1]), float(axis[2]), float(angle)])

    def driver(self):
        if self.exit_t is None or None in self.parts.values():
            return
        t = self.sv.getTime() - self.exit_t
        if not self.seat_hidden:
            self.seat_hidden = True
            try:
                seat = self.ego.getField('sensorsSlotCenter').getMFNode(2)
                seat.getField('translation').setSFVec3f([1.2, 0.38, -5.0])
            except Exception:
                pass
            self.x0 = self.ego.getPosition()[0] + 1.3
        X_IN, y = 507.2, -830.35
        x = self.x0 if t < 1.0 else min(self.x0 + 1.25 * (t - 1.0), X_IN)
        inside = x >= X_IN
        sw = 0.0 if (t < 1.0 or inside) else 0.45 * math.sin(2 * math.pi * 0.9 * (t - 1.0))
        z = -20.0 if inside else 0.0
        self._put('D_BODY', x, y, z)
        self._put('D_LLEG', x, y + 0.1, z + 0.92, sw)
        self._put('D_RLEG', x, y - 0.1, z + 0.92, -sw)
        self._put('D_LARM', x, y + 0.27, z + 1.47, -0.8 * sw)
        self._put('D_RARM', x, y - 0.27, z + 1.47, 0.8 * sw)
        if not inside:
            door = min(1.4, max(0.0, (x - 503.8) / 1.5 * 1.4))
            self.t_in = None
        else:
            if self.t_in is None:
                self.t_in = t
            door = max(0.0, 1.4 - (t - self.t_in - 0.8) * 1.4) if t - self.t_in > 0.8 else 1.4
            if t - self.t_in > 1.5:
                self._put('HOUSE_LIGHT', 505.95, -830, 3.9)        # la lumiere s'allume a l'etage
        self._put('HOUSE_DOOR', 505.93, -829.35, 0.0, door, (0, 0, 1))

    def label(self, i, text, x, y, size, color):
        if self.lbl.get(i) == (text, color):
            return
        self.lbl[i] = (text, color)
        self.sv.setLabel(50 + i, text, x + 0.0015, y + 0.0025, size, BLACK, 0.2, 'Arial')     # ombre
        self.sv.setLabel(i, text, x, y, size, color, 0.0, 'Arial')

    def ambiance(self):
        p = self.ego.getPosition()
        a = 0.0 if p[1] > -800 else min(max((p[0] - X_DUSK) / (X_NIGHT - X_DUSK), 0.0), 1.0)
        f = NIGHT if a >= 1 else (1 - a) + a * NIGHT
        if self.f is None or abs(f - self.f) > 0.02 * max(self.f, 0.01) or (a >= 1 and self.f != NIGHT):
            self.f = f
            self.sun_i.setSFFloat(float(2.6 * f)); self.sun_a.setSFFloat(float(f))
            self.sky.setSFFloat(float(max(f, 0.02)))
            k = max(f, 0.05)
            self.fog_color.setSFColor([float(0.38 * k), float(0.35 * k), float(0.32 * k)])
            self.fog_range.setSFFloat(1000.0 if a < 1 else 350.0)
        return a

    def lamps(self):
        """Luminosite des phares halogenes : flux ~ (tension efficace / 13,2 V) ^ 3,4.
        Tension efficace = racine(PWM) x tension batterie (sortie du bloc B7 du calculateur)."""
        d, vb = self.v['duty'], self.v['vbat']
        for key, ch in (('low', 0), ('high', 2)):
            if key not in self.spot or d[ch] <= 0:
                continue
            veff = math.sqrt(d[ch] / 100.0) * vb
            rel = min(1.0, veff / 13.2) ** 3.4
            if key == 'low':
                self.rel = rel
            f, base, last = self.spot[key]
            if last is None or abs(rel - last) > 0.005:
                f.setSFFloat(float(base * rel))
                self.spot[key][2] = rel

    def step(self):
        rclpy.spin_once(self.node, timeout_sec=0)
        if not self.ok:
            return
        a = self.ambiance()
        self.driver()
        self.k += 1
        if self.k % 5:
            return                                                      # HUD rafraichi toutes les 50 ms
        v, d = self.v, self.v['duty']
        self.label(0, 'LIGHTING SYSTEM CONTROL  -  calculateur LSC (code C Embedded Coder) pilote par ROS 2', 0.01, 0.37, 0.045, WHITE)
        self.label(1, '%3.0f km/h' % v['speed'], 0.01, 0.395, 0.13, GREEN if v['speed'] < 60 else ORANGE)
        self.label(2, v['phase'], 0.16, 0.40, 0.10, YELLOW)
        self.label(3, v['detail'], 0.16, 0.445, 0.06, WHITE)
        moment = 'JOUR' if a == 0 else ('NUIT' if a >= 1 else 'CREPUSCULE')
        self.label(4, 'Luminosite : %.0f lux  (%s)%s' % (v['lux'], moment, '   >>> TUNNEL <<<' if v['tunnel'] else ''),
                   0.01, 0.49, 0.055, CYAN)
        feux = ETATS[min(v['state'], 5)]
        col = {0: WHITE, 1: WHITE, 2: WHITE, 3: CYAN, 4: YELLOW, 5: GREEN}[min(v['state'], 5)]
        self.label(5, 'FEUX : %s   |   croisement %d%%   route %d%%' % (feux, d[0], d[2]), 0.01, 0.52, 0.06, col)
        self.label(6, 'Feux de route automatiques (AHB) : %s%s' % (AHB[min(v['ahb'], 4)], '   -  CAMERA : VEHICULE EN FACE' if v['veh'] else ''),
                   0.01, 0.55, 0.055, RED if v['veh'] else WHITE)
        sig = []
        if v['hazard']:
            sig.append('/!\\ DETRESSE /!\\')
        else:
            if d[4] > 0:
                sig.append('<<< CLIGNOTANT GAUCHE')
            if d[5] > 0:
                sig.append('CLIGNOTANT DROIT >>>')
        if v['ess']:
            sig.append('ESS : FEUX STOP CLIGNOTANTS')
        elif d[6] >= 90:
            sig.append('FEUX STOP')
        self.label(7, '   '.join(sig), 0.01, 0.585, 0.07, ORANGE if not v['ess'] else RED)
        self.label(8, ('DTC memorise : %d (defaut lampe)' % v['dtc']) if v['dtc'] else '', 0.01, 0.625, 0.05, RED)
        self.lamps()
        soc = v['soc']
        self.label(9, 'BATTERIE : %3.0f %%  (%.1f V)   |   intensite des phares : %3.0f %%' % (soc, v['vbat'], 100 * self.rel),
                   0.01, 0.655, 0.055, GREEN if soc > 80 else (YELLOW if soc > 65 else ORANGE))
