"""Superviseur d'ambiance du trajet complet : fait tomber la nuit selon la position de la Tesla.

Jour (x < 150 m) -> crepuscule (150 a 270 m) -> nuit (x > 270 m). Le soleil, le ciel et le brouillard
sont assombris ensemble : le capteur de lumiere de la voiture mesure donc vraiment la baisse de luminosite.
Auteur : Amina Borcheni - PFE M2 IAA ENET'Com
"""
import rclpy
from std_msgs.msg import Float64

X_DUSK, X_NIGHT, NIGHT = 150.0, 270.0, 0.0008     # debut / fin du crepuscule [m], luminosite de nuit


class AmbiancePlugin:
    def init(self, webots_node, properties):
        self.sv = webots_node.robot
        self.f = None
        self.ego = self.sv.getFromDef('EGO')
        sun, sky, fog = (self.sv.getFromDef(n) for n in ('SUN', 'SKY', 'FOG'))
        self.ok = None not in (self.ego, sun, sky, fog)      # monde sans cycle jour/nuit : rien a faire
        if self.ok:
            self.sun_i = sun.getField('intensity')
            self.sun_a = sun.getField('ambientIntensity')
            self.sky = sky.getField('luminosity')
            self.fog_color = fog.getField('color')
            self.fog_range = fog.getField('visibilityRange')
        if not rclpy.ok():
            rclpy.init(args=None)
        self.node = rclpy.create_node('lsc_ambiance')
        self.pub = self.node.create_publisher(Float64, '/lsc/ambiance/daylight', 10)

    def step(self):
        if not self.ok:
            return
        x = self.ego.getPosition()[0]
        a = min(max((x - X_DUSK) / (X_NIGHT - X_DUSK), 0.0), 1.0)
        f = (1 - a) * 1.0 + a * NIGHT
        f = f if a < 1 else NIGHT
        if self.f is None or abs(f - self.f) > 0.02 * max(self.f, 0.01) or (a == 1 and self.f != NIGHT):
            self.f = f
            self.sun_i.setSFFloat(float(2.6 * f))       # lumiere directe du soleil
            self.sun_a.setSFFloat(float(1.0 * f))       # lumiere ambiante (aussi mesuree par le capteur)
            self.sky.setSFFloat(float(max(f, 0.02)))
            k = max(f, 0.05)
            self.fog_color.setSFColor([float(0.38 * k), float(0.35 * k), float(0.32 * k)])
            self.fog_range.setSFFloat(1000.0 if a < 1 else 300.0)
            self.pub.publish(Float64(data=f))
