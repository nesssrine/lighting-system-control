"""Trace le journal ~/lsc_log.csv du tableau de bord et enregistre la figure dans le dossier du projet Windows."""
import os
import sys
import csv
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt


def main():
    src = os.path.expanduser('~/lsc_log.csv')
    out = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.environ.get('LSC_RESULTS', os.path.expanduser('~/lsc_results')), 'VIRT_trajet.png')
    os.makedirs(os.path.dirname(os.path.abspath(out)), exist_ok=True)
    rows = list(csv.DictReader(open(src)))
    col = lambda k: [float(r[k]) for r in rows]
    t = col('t')
    fig, ax = plt.subplots(4, 1, figsize=(10, 8), sharex=True)
    ax[0].plot(t, col('lux'), label='lux capteur'); ax[0].plot(t, col('lux_filt'), '--', label='lux filtre (B1)')
    ax[0].set_yscale('symlog', linthresh=10); ax[0].set_ylabel('Lux'); ax[0].legend(loc='upper right')
    ax[0].fill_between(t, 0, 1e5, where=[x > 0 for x in col('tunnel')], color='grey', alpha=0.3, step='post')
    ax[0].set_title('Vehicule virtuel Webots + ROS 2 : reponse du calculateur LSC')
    ax[1].step(t, col('light_state'), 'k', where='post'); ax[1].set_yticks(range(6))
    ax[1].set_yticklabels(['OFF', 'DRL', 'POSITION', 'CROIS.', 'ROUTE', 'FMH'])
    ax[2].step(t, col('duty_low_L'), 'b', where='post', label='Croisement'); ax[2].step(t, col('duty_high'), 'm', where='post', label='Route')
    ax[2].set_ylabel('PWM [%]'); ax[2].legend(loc='upper right')
    ax[3].plot(t, col('speed'), 'g'); ax[3].set_ylabel('km/h'); ax[3].set_xlabel('Temps [s]')
    ax3b = ax[3].twinx(); ax3b.step(t, col('ahb_state'), 'r', where='post'); ax3b.set_yticks(range(5))
    ax3b.set_yticklabels(['OFF', 'PRET', 'ACTIF', 'PAUSE', 'DEFAUT'], color='r')
    for a in ax:
        a.grid(alpha=0.3)
    plt.tight_layout(); plt.savefig(out, dpi=110)
    print('Figure enregistree :', out)
