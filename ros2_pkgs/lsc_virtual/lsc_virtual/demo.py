"""Demonstration automatique du calculateur LSC sur route (virages, tunnel, ESS, nuit, maison).

Joue le role du conducteur, affiche la phase en cours dans Webots (/lsc/phase) et verifie le
cahier des charges : verdict PASS/FAIL ecrit dans le dossier du projet Windows.
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import os
import time
import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool, Float64, Int32, String, UInt8, UInt16, UInt8MultiArray

OBST_X = -110.0      # voiture en panne sur la voie de droite (route C)
OUT = os.environ.get('LSC_RESULTS', os.path.expanduser('~/lsc_results'))
COLS = ['t', 's', 'x', 'speed', 'lux', 'lux_filt', 'tunnel', 'veh', 'state', 'ahb', 'd_lowL', 'd_high', 'd_drl',
        'd_blkL', 'd_blkR', 'd_rear', 'hazard', 'ess', 'fmh', 'dtc']


class Demo(Node):
    def __init__(self):
        super().__init__('lsc_demo')
        self.v = dict(s=0.0, x=-700.0, speed=0.0, lux=0.0, lux_filt=0.0, tunnel=False, veh=False, state=0, ahb=0,
                      duty=[0] * 8, hazard=False, ess=False, fmh=False, dtc=0)
        sub = self.create_subscription
        for k, typ, topic in (('s', Float64, '/lsc/in/s'), ('x', Float64, '/lsc/in/x'), ('speed', Float64, '/lsc/in/speed'),
                              ('lux', Float64, '/lsc/in/lux'), ('tunnel', Bool, '/lsc/in/in_tunnel'), ('veh', Bool, '/lsc/in/vehicle_detected'),
                              ('lux_filt', Float64, '/lsc/out/lux_filt'), ('ahb', UInt8, '/lsc/out/ahb_state'),
                              ('hazard', Bool, '/lsc/out/hazard'), ('ess', Bool, '/lsc/out/ess'), ('fmh', Bool, '/lsc/out/fmh'),
                              ('dtc', UInt16, '/lsc/out/dtc')):
            sub(typ, topic, lambda m, k=k: self.v.__setitem__(k, m.data), 10)
        sub(UInt8MultiArray, '/lsc/out/duty', lambda m: self.v.__setitem__('duty', list(m.data)), 10)
        sub(UInt8, '/lsc/out/light_state', self._state, 10)
        self.t_ecu = None
        self.pubs, self.rows, self.ev, self.done = {}, [], {}, set()
        self.t0 = time.time()
        self.stop1 = self.stop2 = self.fmh_end = None
        self.n_veh = 0
        self.veh_prev = False
        self.finished = False
        self.result = ''
        self.create_timer(0.01, self.tick)
        self.get_logger().info('Demonstration LSC demarree (environ 3 min 30)')

    def _state(self, m):
        self.v['state'] = m.data
        if self.t_ecu is None:
            self.t_ecu = time.time() - self.t0

    def pub(self, topic, typ, val):
        if topic not in self.pubs:
            self.pubs[topic] = self.create_publisher(typ, topic, 10)
        self.pubs[topic].publish(typ(data=val))

    def cmd(self, name, val):
        self.pub('/lsc/cmd/' + name, Bool, val)

    def phase(self, title, detail=''):
        self.title, self.detail = title, detail

    def once(self, name, cond, t, action=None):
        if name not in self.done and cond:
            self.done.add(name)
            self.ev[name] = t
            self.get_logger().info('[%6.1f s] %s' % (t, name))
            if action:
                action()

    def tick(self):
        if self.finished:
            return
        t = time.time() - self.t0
        s, E, on, v = self.v['s'], self.ev, self.once, self.v
        if not hasattr(self, 'title'):
            self.phase('DEPART - JOUR', 'Contact mis, commodo AUTO : feux de jour (DRL) allumes')
        on('depart', True, t, lambda: (self.cmd('ignition', True), self.pub('/lsc/cmd/lamp_fail', Int32, 0),
                                      self.pub('/lsc/cmd/target_speed', Float64, 50.0)))
        on('virage_droite', s >= 110, t, lambda: (self.cmd('turn_right', True), self.pub('/lsc/cmd/target_speed', Float64, 30.0),
                                                 self.phase('VIRAGE A DROITE', 'Clignotant droit avant + arriere, 1,5 Hz (REQ-LSC-16)')))
        on('fin_virage_droite', s >= 268, t, lambda: (self.cmd('turn_right', False), self.pub('/lsc/cmd/target_speed', Float64, 50.0),
                                                     self.phase('TUNNEL EN VUE', 'Plein jour : environ 31 000 lux')))
        on('tunnel_entree', v['tunnel'], t, lambda: self.phase('TUNNEL', '150 lux : croisement allume en 0,3 s (REQ-LSC-08)'))
        on('tunnel_sortie', 'tunnel_entree' in E and not v['tunnel'], t,
           lambda: self.phase('SORTIE DU TUNNEL', 'Croisement maintenu 5 s puis retour aux feux de jour (REQ-LSC-07)'))
        on('ampoule_grillee', s >= 372, t, lambda: (self.pub('/lsc/cmd/lamp_fail', Int32, 4),
                                                   self.phase('AMPOULE GRILLEE', 'Ampoule AVANT gauche grillee (elle reste eteinte) : detectee par le diagnostic B6')))
        on('virage_gauche', s >= 382, t, lambda: (self.cmd('turn_left', True), self.pub('/lsc/cmd/target_speed', Float64, 30.0),
                                                 self.phase('VIRAGE A GAUCHE - HYPER-CLIGNOTEMENT', 'Ampoule avant gauche grillee : l\'arriere gauche clignote 2x plus vite (REQ-LSC-23)')))
        on('fin_virage_gauche', s >= 482, t, lambda: (self.cmd('turn_left', False), self.pub('/lsc/cmd/target_speed', Float64, 50.0),
                                                     self.phase('LIGNE DROITE', 'DTC memorise : la lampe sera signalee au garage')))
        on('acceleration', s >= 505, t, lambda: (self.pub('/lsc/cmd/target_speed', Float64, 85.0),
                                                self.phase('ACCELERATION FORTE', 'Le conducteur accelere jusqu\'a 85 km/h')))
        gap = OBST_X - v['x']                                   # distance a l'obstacle [m]
        on('obstacle_en_vue', 'acceleration' in E and gap <= 140, t,
           lambda: self.phase('OBSTACLE EN VUE', 'Voiture en panne sur la voie : le conducteur va freiner'))
        on('freinage_urgence', 'acceleration' in E and ((gap <= 70 and v['speed'] > 60) or gap <= 50), t,
           lambda: (self.cmd('brake', True), self.cmd('stop', True),
                    self.phase("FREINAGE D'URGENCE - OBSTACLE", 'Deceleration > 6 m/s2 au-dessus de 50 km/h : feux stop clignotants (ESS, REQ-LSC-20)')))
        if 'freinage_urgence' in E and self.stop1 is None and v['speed'] < 1:
            self.stop1 = t
            on('arret_urgence', True, t, lambda: self.phase('ARRET DEVANT L\'OBSTACLE - DETRESSE AUTOMATIQUE',
                                                           'Apres le freinage d\'urgence, les feux de detresse s\'allument seuls (REQ-LSC-21)'))
        if self.stop1 is not None:
            on('pedale_relachee', t - self.stop1 > 3, t, lambda: self.cmd('brake', False))
            on('redemarrage', t - self.stop1 > 6, t, lambda: (self.cmd('stop', False), self.cmd('turn_left', True),
                                                             self.pub('/lsc/cmd/lane_offset', Float64, 4.0), self.pub('/lsc/cmd/target_speed', Float64, 15.0),
                                                             self.phase("CONTOURNEMENT DE L'OBSTACLE", 'Clignotant gauche ; au-dessus de 10 km/h la detresse automatique s\'eteint (REQ-LSC-21)')))
            on('retour_voie', 'redemarrage' in E and v['x'] > OBST_X + 10, t,
               lambda: (self.cmd('turn_left', False), self.cmd('turn_right', True), self.pub('/lsc/cmd/lane_offset', Float64, 0.0),
                        self.phase('RETOUR SUR LA VOIE', 'Obstacle depasse : clignotant droit, retour sur la voie de droite')))
            on('obstacle_passe', 'retour_voie' in E and v['x'] > OBST_X + 35, t,
               lambda: (self.cmd('turn_right', False), self.pub('/lsc/cmd/target_speed', Float64, 50.0),
                        self.phase('LIGNE DROITE', 'Le trajet continue apres l\'obstacle')))
        on('crepuscule', 'obstacle_passe' in E and v['x'] > -70, t,
           lambda: self.phase('CREPUSCULE', 'La luminosite baisse : croisement automatique sous 1000 lux (REQ-LSC-06)'))
        on('nuit', 'crepuscule' in E and v['x'] > 20, t,
           lambda: self.phase('NUIT - FEUX DE ROUTE AUTOMATIQUES', 'Nuit + plus de 40 km/h + route libre : feux de route (AHB)'))
        if 'nuit' in E and v['veh'] != self.veh_prev:
            self.veh_prev = v['veh']
            if v['veh']:
                self.n_veh += 1
                on('vehicule_%d' % self.n_veh, True, t, lambda: self.phase('VEHICULE EN FACE', 'La camera le detecte : feux de route coupes pour ne pas l\'eblouir (REQ-LSC-13)'))
            else:
                on('vehicule_%d_croise' % self.n_veh, True, t, lambda: self.phase('ROUTE LIBRE', 'Feux de route rallumes 2 s apres (REQ-LSC-12)'))
        on('arrivee', s >= 1290, t, lambda: (self.pub('/lsc/cmd/target_speed', Float64, 25.0),
                                            self.phase('ARRIVEE A LA MAISON', 'Ralentissement : sous 30 km/h, les feux de route automatiques s\'arretent')))
        on('freinage_maison', s >= 1376, t, lambda: self.pub('/lsc/cmd/brake_level', Float64, 0.5))
        if 'freinage_maison' in E and self.stop2 is None and v['speed'] < 0.5:
            self.stop2 = t
            on('stationnement', True, t, lambda: self.phase('STATIONNEMENT DEVANT LA MAISON', ''))
        if self.stop2 is not None:
            on('contact_coupe', t - self.stop2 > 2, t, lambda: (self.cmd('ignition', False),
                                                             self.phase('CONTACT COUPE - FOLLOW-ME-HOME', 'Nuit + commodo AUTO : les feux eclairent le chemin (REQ-LSC-25)')))
            on('porte_ouverte', t - self.stop2 > 4, t, lambda: (self.cmd('door_closed', False), self.phase('PORTE OUVERTE', 'Le conducteur descend de la voiture')))
            on('porte_fermee', t - self.stop2 > 5, t, lambda: self.cmd('door_closed', True))
            if 'porte_fermee' in E:
                left = 30 - (t - E['porte_fermee'])
                if v['state'] == 5 and left > -2:
                    self.phase('FOLLOW-ME-HOME', 'Les phares eclairent le chemin du conducteur - extinction dans %d s' % max(0, round(left)))
                on('fmh_eteint', 'porte_fermee' in E and t - E['porte_fermee'] > 1 and v['state'] == 0, t)
            if 'fmh_eteint' in E:
                self.phase('FIN DE LA DEMONSTRATION', self.result or 'Tous les feux sont eteints')
                if not self.result:
                    self.report()
                if t - E['fmh_eteint'] > 8 or t > 900:
                    self.finished = True
        if t > 900 and not self.result:
            self.report(); self.finished = True
        # batterie : moteur tournant (alternateur) 14,2 V -> 13,4 V au fil du trajet ; contact coupe : 12,6 V -> 12,1 V
        if 'contact_coupe' not in E:
            k = min(max(s / 1376.0, 0.0), 1.0)
            vbat, soc = 14.2 - 0.8 * k, 100.0 - 10.0 * k
        else:
            k = min((t - E['contact_coupe']) / 40.0, 1.0)
            vbat, soc = 12.6 - 0.5 * k, 88.0 - 18.0 * k
        self.pub('/lsc/in/vbat', Float64, vbat)
        self.pub('/lsc/in/soc', Float64, soc)
        self.pub('/lsc/phase', String, self.title)
        self.pub('/lsc/phase_detail', String, self.detail)
        d = v['duty']
        if int(t * 100) % 2 == 0:
            self.rows.append((t, s, v['x'], v['speed'], v['lux'], v['lux_filt'], int(v['tunnel']), int(v['veh']), v['state'], v['ahb'],
                              d[0], d[2], d[3], d[4], d[5], d[6], int(v['hazard']), int(v['ess']), int(v['fmh']), v['dtc']))

    # ---------- verification du cahier des charges
    def report(self):
        R, E = self.rows, self.ev
        I = {c: i for i, c in enumerate(COLS)}
        win = lambda a, b: [r for r in R if a <= r[0] <= b]
        val = lambda c, a, b: [r[I[c]] for r in win(a, b)]
        def first(c, cond, a, b=1e9):
            for r in win(a, b):
                if cond(r[I[c]]):
                    return r[0] - a
            return None
        def edges(c, a, b, th=0):
            vs = val(c, a, b)
            return sum(1 for i in range(1, len(vs)) if vs[i] > th and vs[i - 1] <= th)
        res = []
        def check(code, req, desc, ok, mesure=''):
            res.append((code, req, desc, 'PASS' if ok else 'FAIL', mesure))
        g = E.get
        fmt = lambda x: 'aucune' if x is None else '%.2f s' % x
        t0 = (self.t_ecu or 2) + 0.1
        st = val('state', t0, g('virage_droite', t0 + 5))
        check('D-01', 'REQ-LSC-05', 'Depart de jour : feux de jour (DRL) seuls', len(st) > 0 and set(st) == {1}, 'etats %s' % sorted(set(st)))
        a = g('virage_droite', 0); n = edges('d_blkR', a + 0.5, a + 4.5)
        check('D-02', 'REQ-LSC-16', 'Virage a droite : clignotant droit a 1,5 Hz', 5 <= n <= 7, '%d impulsions en 4 s' % n)
        a = g('tunnel_entree'); dt = first('state', lambda x: x >= 3, a) if a else None
        check('D-03', 'REQ-LSC-08', 'Entree du tunnel : croisement <= 0,4 s', dt is not None and dt <= 0.45, fmt(dt))
        a = g('tunnel_sortie'); dt = first('state', lambda x: x == 1, a) if a else None
        check('D-04', 'REQ-LSC-07', 'Sortie du tunnel : feux de jour apres 5 s de lumiere', dt is not None and 4.5 <= dt <= 6.5, fmt(dt))
        a = g('virage_gauche', 0); n = edges('d_blkL', a + 0.5, a + 4.5)
        check('D-05', 'REQ-LSC-23', 'Virage a gauche, lampe grillee : hyper-clignotement (3 Hz)', n >= 10, '%d impulsions en 4 s' % n)
        check('D-06', 'Diag B6', 'Lampe grillee memorisee (DTC)', any(x > 0 for x in val('dtc', a, a + 8)), 'DTC = %d' % max(val('dtc', a, a + 8) or [0]))
        vmax = max(val('speed', g('acceleration', 0), g('freinage_urgence', 1e9)) or [0])
        a = g('freinage_urgence', 0)
        e_ok = any(val('ess', a, a + 4)); n = edges('d_rear', a, a + 3, 50)
        check('D-07', 'REQ-LSC-20', "Freinage d'urgence a %.0f km/h : feux stop clignotants (ESS)" % vmax, e_ok and n >= 3, '%d eclats des feux stop' % n)
        a = g('arret_urgence', 0)
        check('D-08', 'REQ-LSC-21', "Arret apres freinage d'urgence : detresse automatique", any(val('hazard', a, a + 3)))
        a = g('redemarrage', 0)
        dt = first('hazard', lambda x: x == 0, a + 1) if a else None
        check('D-09', 'REQ-LSC-21', 'Redemarrage > 10 km/h : detresse automatique eteinte', dt is not None and dt < 10, fmt(dt))
        a = g('crepuscule', 0)
        check('D-10', 'REQ-LSC-06', 'Crepuscule : croisement automatique', any(x >= 3 for x in val('state', a, a + 15)))
        a, b = g('nuit', 0), g('vehicule_1', g('nuit', 0) + 30)
        hi = val('d_high', a, b)
        check('D-11', 'REQ-LSC-10/11', 'Nuit, route libre : feux de route automatiques', any(x > 0 for x in hi), '%.1f s de feux de route' % (sum(1 for x in hi if x > 0) * 0.02))
        ok12, ok13, m12, m13 = True, True, [], []
        for k in (1, 2):
            a, b = g('vehicule_%d' % k), g('vehicule_%d_croise' % k)
            d1 = first('d_high', lambda x: x == 0, a) if a else None
            d2 = first('d_high', lambda x: x > 0, b) if b else None
            ok12 &= d1 is not None and d1 < 0.5; ok13 &= d2 is not None and 1.8 <= d2 <= 3.0
            m12.append(fmt(d1)); m13.append(fmt(d2))
        check('D-12', 'REQ-LSC-13', 'Vehicule en face (x2) : feux de route coupes', ok12, ' / '.join(m12))
        check('D-13', 'REQ-LSC-12', 'Route libre (x2) : feux de route rallumes apres 2 s', ok13, ' / '.join(m13))
        a = g('contact_coupe', 0)
        check('D-14', 'REQ-LSC-25', 'Contact coupe de nuit devant la maison : follow-me-home', any(x == 5 for x in val('state', a, a + 3)))
        a = g('porte_fermee'); dt = (g('fmh_eteint') - a) if a and g('fmh_eteint') else None
        check('D-15', 'REQ-LSC-25', 'Follow-me-home : extinction 30 s apres la porte', dt is not None and 28.5 <= dt <= 31.5, fmt(dt))
        npass = sum(1 for r in res if r[3] == 'PASS')
        self.result = '%d / %d tests PASS' % (npass, len(res))
        os.makedirs(OUT, exist_ok=True)
        with open(os.path.join(OUT, 'DEMO_resultats.txt'), 'w') as f:
            f.write('DEMONSTRATION ROS 2 + Webots (virages, tunnel, ESS, nuit, maison) - %s\n' % self.result)
            for r in res:
                f.write('[%s] %-5s %-14s %-62s %s\n' % (r[3], r[0], r[1], r[2], r[4]))
            f.write('\nEvenements (temps reel depuis le debut) :\n')
            for k, tt in sorted(E.items(), key=lambda kv: kv[1]):
                f.write('  %7.2f s  %s\n' % (tt, k))
        with open(os.path.join(OUT, 'DEMO_log.csv'), 'w') as f:
            f.write(','.join(COLS) + '\n')
            for r in R:
                f.write(','.join('%.2f' % x if isinstance(x, float) else str(x) for x in r) + '\n')
        for r in res:
            print('[%s] %s %s %s %s' % (r[3], r[0], r[1], r[2], r[4]), flush=True)
        print('\n==> %s. Resultats : %s' % (self.result, OUT), flush=True)


def main():
    rclpy.init()
    n = Demo()
    try:
        while rclpy.ok() and not n.finished:
            rclpy.spin_once(n, timeout_sec=0.05)
    except (KeyboardInterrupt, Exception):
        pass
    if not n.result:
        n.report()
