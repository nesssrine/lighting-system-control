"""Scenario automatique du trajet complet : joue le role du conducteur et verifie le cahier des charges.

Le noeud declenche les evenements selon la position de la Tesla sur la piste (jour, tunnel, crepuscule,
nuit, vehicules en face, freinage d'urgence, coupure du contact), enregistre toutes les sorties du
calculateur et ecrit un verdict PASS/FAIL par exigence dans le dossier du projet Windows.
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import os
import time
import rclpy
from rclpy.node import Node
from std_msgs.msg import Bool, Float64, Int32, UInt8, UInt16, UInt8MultiArray

OUT = os.environ.get('LSC_RESULTS', os.path.expanduser('~/lsc_results'))
COLS = ['t', 'x', 'speed', 'lux', 'lux_filt', 'tunnel', 'veh', 'state', 'ahb', 'd_lowL', 'd_lowR', 'd_high',
        'd_blkL', 'd_blkR', 'd_rear', 'hazard', 'ess', 'fmh', 'dtc', 'ev']


class Scenario(Node):
    def __init__(self):
        super().__init__('lsc_scenario')
        self.v = dict(x=-300.0, speed=0.0, lux=0.0, lux_filt=0.0, tunnel=False, veh=False, state=0, ahb=0,
                      duty=[0] * 8, hazard=False, ess=False, fmh=False, dtc=0)
        s = self.create_subscription
        for k, typ, topic in (('x', Float64, '/lsc/in/x'), ('speed', Float64, '/lsc/in/speed'), ('lux', Float64, '/lsc/in/lux'),
                              ('tunnel', Bool, '/lsc/in/in_tunnel'), ('veh', Bool, '/lsc/in/vehicle_detected'),
                              ('lux_filt', Float64, '/lsc/out/lux_filt'), ('state', UInt8, '/lsc/out/light_state'),
                              ('ahb', UInt8, '/lsc/out/ahb_state'), ('hazard', Bool, '/lsc/out/hazard'), ('ess', Bool, '/lsc/out/ess'),
                              ('fmh', Bool, '/lsc/out/fmh'), ('dtc', UInt16, '/lsc/out/dtc')):
            s(typ, topic, lambda m, k=k: self.v.__setitem__(k, m.data), 10)
        s(UInt8MultiArray, '/lsc/out/duty', lambda m: self.v.__setitem__('duty', list(m.data)), 10)
        self.t_ecu = None       # instant du premier message recu du calculateur (decouverte ROS 2)
        s(UInt8, '/lsc/out/light_state', self._first_ecu, 10)
        self.pubs = {}
        self.t0 = time.time()
        self.rows = []
        self.ev = {}            # nom -> instant
        self.done = set()
        self.stop_t = None
        self.finished = False
        self.create_timer(0.01, self.tick)
        self.get_logger().info('Scenario automatique LSC demarre (environ 3 minutes)')

    def _first_ecu(self, m):
        if self.t_ecu is None:
            self.t_ecu = time.time() - self.t0

    # ---------- outils
    def pub(self, topic, typ, val):
        if topic not in self.pubs:
            self.pubs[topic] = self.create_publisher(typ, topic, 10)
        self.pubs[topic].publish(typ(data=val))

    def b(self, name, val):
        self.pub('/lsc/cmd/' + name, Bool, val)

    def mark(self, name, t):
        self.ev[name] = t
        self.done.add(name)
        self.get_logger().info('[%6.1f s] %s' % (t, name))

    def once(self, name, cond, t, action=None):
        if name not in self.done and cond:
            self.mark(name, t)
            if action:
                action()

    # ---------- deroulement
    def tick(self):
        if self.finished:
            return
        t = time.time() - self.t0
        x = self.v['x']
        E = self.ev
        on = self.once
        on('depart', True, t, lambda: self.b('ignition', True))
        # --- jour
        on('clignotant_impulsion', x > -280, t, lambda: self.b('turn_left', True))
        on('clignotant_relache', 'clignotant_impulsion' in E and t - E['clignotant_impulsion'] > 0.3, t, lambda: self.b('turn_left', False))
        on('capteur_defaut', 'tunnel_sortie' in E and x > -20, t, lambda: self.b('sensor_fault', True))
        on('capteur_retour', 'capteur_defaut' in E and t - E['capteur_defaut'] > 1.5, t, lambda: self.b('sensor_fault', False))
        on('tunnel_entree', self.v['tunnel'], t)
        on('tunnel_sortie', 'tunnel_entree' in E and not self.v['tunnel'], t)
        on('ampoule_clignotant_D_grillee', x > 90, t,
           lambda: (self.pub('/lsc/cmd/lamp_fail', Int32, 8), self.b('turn_right', True)))
        on('clignotant_D_coupe', 'ampoule_clignotant_D_grillee' in E and t - E['ampoule_clignotant_D_grillee'] > 4, t,
           lambda: (self.b('turn_right', False), self.pub('/lsc/cmd/lamp_fail', Int32, 0)))
        on('detresse_on', x > 160, t, lambda: self.b('hazard', True))
        on('detresse_off', 'detresse_on' in E and t - E['detresse_on'] > 3, t, lambda: self.b('hazard', False))
        # --- crepuscule et nuit
        on('nuit', x > 270, t)
        on('vehicule_1', 'nuit' in E and self.v['veh'], t)
        on('vehicule_1_croise', 'vehicule_1' in E and x > 455, t)
        on('appel_phares', x > 530, t, lambda: self.b('flash', True))
        on('appel_relache', 'appel_phares' in E and t - E['appel_phares'] > 0.6, t, lambda: self.b('flash', False))
        on('camera_panne', x > 600, t, lambda: self.b('cam_fault', True))
        on('camera_retour', 'camera_panne' in E and t - E['camera_panne'] > 3, t, lambda: self.b('cam_fault', False))
        on('vehicule_2', 'camera_retour' in E and x > 680 and self.v['veh'], t)
        on('vehicule_2_croise', 'vehicule_2' in E and x > 805, t)
        on('acceleration_70', x > 850, t, lambda: self.pub('/lsc/cmd/target_speed', Float64, 70.0))
        on('freinage_urgence', x > 1050, t, lambda: (self.b('brake', True), self.b('stop', True)))
        if 'freinage_urgence' in E and self.stop_t is None and self.v['speed'] < 1:
            self.stop_t = t
            self.mark('arret', t)
        # --- arrivee : coupure du contact de nuit, porte
        if self.stop_t is not None:
            on('frein_relache', t - self.stop_t > 3, t, lambda: self.b('brake', False))
            on('contact_coupe', t - self.stop_t > 4, t, lambda: self.b('ignition', False))
            on('porte_ouverte', t - self.stop_t > 6, t, lambda: self.b('door_closed', False))
            on('porte_fermee', t - self.stop_t > 7, t, lambda: self.b('door_closed', True))
            on('fin', t - self.stop_t > 42, t)
        v = self.v; d = v['duty']
        evn = ';'.join(k for k, tt in E.items() if abs(tt - t) < 0.006)
        self.rows.append((t, x, v['speed'], v['lux'], v['lux_filt'], int(v['tunnel']), int(v['veh']), v['state'], v['ahb'],
                          d[0], d[1], d[2], d[4], d[5], d[6], int(v['hazard']), int(v['ess']), int(v['fmh']), v['dtc'], evn))
        if 'fin' in E or t > 700:
            self.finished = True
            self.report()

    # ---------- verification du cahier des charges
    def report(self):
        os.makedirs(OUT, exist_ok=True)
        R = self.rows
        I = {c: i for i, c in enumerate(COLS)}
        E = self.ev
        def win(a, b):
            return [r for r in R if a <= r[0] <= b]
        def val(c, a, b):
            return [r[I[c]] for r in win(a, b)]
        def first(c, cond, a, b=1e9):
            for r in win(a, b):
                if cond(r[I[c]]):
                    return r[0] - a
            return None
        def edges(c, a, b):
            vs = val(c, a, b); return sum(1 for i in range(1, len(vs)) if vs[i] > 0 and vs[i - 1] == 0)
        res = []
        def check(code, req, desc, ok, mesure):
            res.append((code, req, desc, 'PASS' if ok else 'FAIL', mesure))
        g = E.get
        t1 = g('clignotant_impulsion', 0)
        t0e = (self.t_ecu or 2.0) + 0.1    # on verifie a partir du premier message du calculateur
        st = val('state', t0e, t1)
        check('V-01', 'REQ-LSC-05', 'Jour, contact mis : DRL seuls', len(st) > 0 and all(s == 1 for s in st), 'etat=%s' % sorted(set(st)))
        n = edges('d_blkL', t1, t1 + 3)
        check('V-02', 'REQ-LSC-17', 'Impulsion courte du clignotant : 3 clignotements', n == 3, '%d clignotements' % n)
        tc = g('capteur_defaut', 0)
        dt = first('state', lambda s: s == 3, tc)
        check('V-03', 'REQ-LSC-09', 'Message capteur absent > 0,5 s : croisement (etat sur)', dt is not None and dt < 1.0, 'croisement apres %s s' % (None if dt is None else round(dt, 2)))
        te = g('tunnel_entree'); ts = g('tunnel_sortie')
        dt = first('state', lambda s: s >= 3, te) if te else None
        check('V-04', 'REQ-LSC-08', 'Entree de tunnel : croisement <= 0,4 s', dt is not None and dt <= 0.45, 'apres %s s' % (None if dt is None else round(dt, 2)))
        dt = first('state', lambda s: s == 1, ts) if ts else None
        check('V-05', 'REQ-LSC-07', 'Sortie de tunnel : retour DRL apres 5 s de lumiere', dt is not None and 4.5 <= dt <= 6.5, 'apres %s s' % (None if dt is None else round(dt, 2)))
        th = g('ampoule_clignotant_D_grillee', 0)
        n = edges('d_blkR', th + 0.5, th + 3.5)
        check('V-06', 'REQ-LSC-23', 'Ampoule clignotant D grillee : hyper-clignotement (3 Hz)', n >= 7, '%d impulsions en 3 s' % n)
        check('V-07', 'Diag B6', 'Defaut lampe memorise (DTC)', any(dd > 0 for dd in val('dtc', th, th + 6)), 'DTC max=%d' % max(val('dtc', th, th + 6) or [0]))
        td = g('detresse_on', 0)
        check('V-08', 'Detresse', 'Commande detresse : feux de detresse actifs', any(val('hazard', td + 0.2, td + 2.5)), '')
        tn = g('nuit', 0)
        check('V-09', 'REQ-LSC-06', 'Crepuscule : croisement allume a la tombee de la nuit', any(s >= 3 for s in val('state', tn - 1, tn + 8)), 'lux filtre=%.0f' % (val('lux_filt', tn, tn + 1) or [0])[0])
        tv = g('vehicule_1', tn + 30)
        hi = val('d_high', tn, tv)
        check('V-10', 'REQ-LSC-10/11', 'Nuit, > 40 km/h, route libre : feux de route AHB', any(h > 0 for h in hi), 'route allumee %.1f s' % (sum(1 for h in hi if h > 0) * 0.01))
        dt = first('d_high', lambda h: h == 0, tv) if g('vehicule_1') else None
        check('V-11', 'REQ-LSC-13', 'Vehicule en face detecte par la camera : route coupee', dt is not None and dt < 0.5, 'apres %s s' % (None if dt is None else round(dt, 2)))
        tl = None
        for r in win(tv, tv + 40):
            if r[I['veh']] == 0 and tl is None and r[0] > tv + 0.5:
                tl = r[0]
        dt = first('d_high', lambda h: h > 0, tl) if tl else None
        check('V-12', 'REQ-LSC-12', 'Route libre : feux de route rallumes ~2 s apres', dt is not None and 1.8 <= dt <= 3.0, 'apres %s s' % (None if dt is None else round(dt, 2)))
        tf = g('appel_phares', 0)
        check('V-13', 'REQ-LSC-15', "Appel de phares : route allumee, AHB en pause", any(h > 0 for h in val('d_high', tf + 0.1, tf + 0.5)) and 3 in val('ahb', tf, tf + 1), 'ahb=%s' % sorted(set(val('ahb', tf, tf + 1))))
        tk = g('camera_panne', 0)
        dt = first('ahb', lambda a: a == 4, tk)
        check('V-14', 'REQ-LSC-14', 'Panne camera : AHB en defaut, route coupee', dt is not None and dt < 0.5 and all(h == 0 for h in val('d_high', tk + 0.5, tk + 2.5)), 'defaut apres %s s' % (None if dt is None else round(dt, 2)))
        tb = g('freinage_urgence', 0)
        check('V-15', 'REQ-LSC-20', "Freinage d'urgence > 50 km/h : feux stop clignotants (ESS)", any(val('ess', tb, tb + 4)), 'deceleration max mesuree dans le journal')
        tco = g('contact_coupe', 0)
        check('V-16', 'REQ-LSC-25', 'Coupure du contact de nuit : follow-me-home', any(s == 5 for s in val('state', tco, tco + 3)), '')
        tp = g('porte_fermee', 0)
        dt = first('state', lambda s: s == 0, tp)
        check('V-17', 'REQ-LSC-25', 'Follow-me-home : extinction 30 s apres la fermeture de la porte', dt is not None and 28.5 <= dt <= 31.5, 'apres %s s' % (None if dt is None else round(dt, 2)))
        npass = sum(1 for r in res if r[3] == 'PASS')
        with open(os.path.join(OUT, 'VIRT_resultats.txt'), 'w') as f:
            f.write('VIRTUALISATION ROS 2 + Webots - trajet complet - %d / %d PASS\n' % (npass, len(res)))
            for r in res:
                f.write('[%s] %-5s %-14s %-62s %s\n' % (r[3], r[0], r[1], r[2], r[4]))
            f.write('\nEvenements (temps reel depuis le debut) :\n')
            for k, tt in sorted(E.items(), key=lambda kv: kv[1]):
                f.write('  %7.2f s  %s\n' % (tt, k))
        with open(os.path.join(OUT, 'VIRT_log.csv'), 'w') as f:
            f.write(','.join(COLS) + '\n')
            for r in R[::2]:
                f.write('%.2f,%.2f,%.1f,%.1f,%.1f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%s\n' % r)
        for r in res:
            print('[%s] %s %s %s %s' % (r[3], r[0], r[1], r[2], r[4]), flush=True)
        print('\n==> %d / %d PASS. Resultats : %s' % (npass, len(res), OUT), flush=True)
        self.get_logger().info('Scenario termine : %d / %d PASS' % (npass, len(res)))


def main():
    rclpy.init()
    n = Scenario()
    try:
        while rclpy.ok() and not n.finished:
            rclpy.spin_once(n, timeout_sec=0.05)
    except (KeyboardInterrupt, Exception):
        pass
    if not n.finished:
        n.finished = True
        n.report()
