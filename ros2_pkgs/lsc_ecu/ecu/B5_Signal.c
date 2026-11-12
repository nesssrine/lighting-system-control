/*
 * File: B5_Signal.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "B5_Signal.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static double tside;

static boolean_T comfort;

static double press_t;

static boolean_T prevL;

static boolean_T prevR;

static double prev_req;

static double ph;

static double cyc;

static boolean_T ess;

static double ph_ess;

static boolean_T ess_seen;

static boolean_T auto_haz;

/* Function Definitions */
/*
 * B5 - Clignotants, feux de detresse, feux stop et signal de freinage d'urgence
 * (ESS) decel : deceleration longitudinale [m/s2], positive quand le vehicule
 * freine
 *
 * Arguments    : boolean_T ignition
 *                boolean_T turn_left
 *                boolean_T turn_right
 *                boolean_T hazard_sw
 *                boolean_T brake_pedal
 *                double speed
 *                double decel
 *                boolean_T fault_L
 *                boolean_T fault_R
 *                boolean_T *blink_L
 *                boolean_T *blink_R
 *                boolean_T *brake_light
 *                boolean_T *hazard_active
 *                boolean_T *ess_active
 * Return Type  : void
 */
void B5_Signal(boolean_T ignition, boolean_T turn_left, boolean_T turn_right,
               boolean_T hazard_sw, boolean_T brake_pedal, double speed,
               double decel, boolean_T fault_L, boolean_T fault_R,
               boolean_T *blink_L, boolean_T *blink_R, boolean_T *brake_light,
               boolean_T *hazard_active, boolean_T *ess_active)
{
  double period;
  double req;
  boolean_T on;
  /*  ---------- 1) Signal de freinage d'urgence ESS (REQ-LSC-20) */
  if ((!ess) && brake_pedal && (decel > 6.0) && (speed > 50.0)) {
    ess = true;
    ph_ess = 0.0;
    ess_seen = true;
    /*  freinage d'urgence detecte */
  } else if (ess && ((decel < 2.5) || (!brake_pedal))) {
    ess = false;
    /*  fin du freinage d'urgence */
  }
  /*  ---------- 2) Feux de detresse automatiques apres arret d'urgence
   * (REQ-LSC-21) */
  if (ess_seen && (speed < 0.5)) {
    auto_haz = true;
    ess_seen = false;
  }
  if (auto_haz && (speed > 10.0)) {
    auto_haz = false;
    /*  le vehicule repart */
  }
  if (hazard_sw || auto_haz) {
    *hazard_active = true;
  } else {
    *hazard_active = false;
  }
  /*  ---------- 3) Demande de clignotement : 0 aucun, 1 gauche, 2 droite, 3
   * detresse */
  if (*hazard_active) {
    req = 3.0;
    /*  detresse prioritaire, meme contact coupe (REQ-LSC-18) */
    tside = 0.0;
    comfort = false;
  } else if (ignition) {
    if (turn_left && (!prevL)) {
      /*  debut d'appui a gauche */
      tside = 1.0;
      press_t = 0.0;
      comfort = false;
    } else if (turn_right && (!prevR)) {
      /*  debut d'appui a droite */
      tside = 2.0;
      press_t = 0.0;
      comfort = false;
    }
    if (((tside == 1.0) && turn_left) || ((tside == 2.0) && turn_right)) {
      press_t += 0.01;
      /*  duree d'appui */
    }
    if (((tside == 1.0) && (!turn_left) && prevL) ||
        ((tside == 2.0) && (!turn_right) && prevR)) {
      if (press_t < 0.5) {
        comfort = true;
        /*  impulsion courte : mode autoroute (REQ-LSC-17) */
      } else {
        tside = 0.0;
        /*  levier relache : arret */
      }
    }
    if (comfort && (cyc >= 3.0)) {
      tside = 0.0;
      comfort = false;
      /*  3 cycles effectues */
    }
    req = tside;
  } else {
    req = 0.0;
    tside = 0.0;
    comfort = false;
  }
  prevL = turn_left;
  prevR = turn_right;
  /*  ---------- 4) Generateur de clignotement (REQ-LSC-16, hyper-clignotement
   * REQ-LSC-23) */
  if (((req == 1.0) && fault_L) || ((req == 2.0) && fault_R) ||
      ((req == 3.0) && (fault_L || fault_R))) {
    period = 0.33333333333333331;
    /*  lampe grillee : frequence doublee */
  } else {
    period = 0.66666666666666663;
  }
  if (req != prev_req) {
    ph = 0.0;
    cyc = 0.0;
    /*  nouvelle demande : on repart d'un flash allume */
  }
  prev_req = req;
  on = false;
  if (req > 0.0) {
    on = (ph < period / 2.0);
    /*  rapport cyclique 50 % */
    ph += 0.01;
    if (ph >= period - 1.0E-9) {
      ph -= period;
      cyc++;
      /*  un cycle complet */
    }
  }
  if (on && ((req == 1.0) || (req == 3.0))) {
    *blink_L = true;
  } else {
    *blink_L = false;
  }
  if (on && ((req == 2.0) || (req == 3.0))) {
    *blink_R = true;
  } else {
    *blink_R = false;
  }
  /*  ---------- 5) Feux stop (REQ-LSC-19) et clignotement ESS */
  if (ess) {
    *brake_light = (ph_ess < 0.125);
    ph_ess += 0.01;
    if (ph_ess >= 0.249999999) {
      ph_ess -= 0.25;
    }
  } else {
    *brake_light = brake_pedal;
    /*  allumage direct a l'appui */
  }
  *ess_active = ess;
}

/*
 * B5 - Clignotants, feux de detresse, feux stop et signal de freinage d'urgence
 * (ESS) decel : deceleration longitudinale [m/s2], positive quand le vehicule
 * freine
 *
 * Arguments    : void
 * Return Type  : void
 */
void B5_Signal_init(void)
{
  tside = 0.0;
  comfort = false;
  press_t = 0.0;
  prevL = false;
  prevR = false;
  prev_req = 0.0;
  ph = 0.0;
  cyc = 0.0;
  ess = false;
  ph_ess = 0.0;
  ess_seen = false;
  auto_haz = false;
}

/*
 * File trailer for B5_Signal.c
 *
 * [EOF]
 */
