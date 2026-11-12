/*
 * File: AHB_Logic.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "AHB_Logic.h"
#include "minOrMax.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static boolean_T spd_ok;

static double clear_cnt;

static boolean_T hb;

/* Function Definitions */
/*
 * B3 - Auto High Beam (AHB) : feux de route automatiques
 *  ahb_state : 0 = OFF (non disponible), 1 = READY (disponible, route non
 * libre) 2 = ACTIVE (feux de route), 3 = PAUSE (action manuelle), 4 = FAULT
 * (camera)
 *
 * Arguments    : boolean_T auto_mode
 *                boolean_T ahb_switch
 *                boolean_T low_beam_on
 *                double speed
 *                double lux
 *                boolean_T vehicle_detected
 *                boolean_T cam_ok
 *                boolean_T manual_override
 *                boolean_T *high_beam
 *                unsigned char *ahb_state
 * Return Type  : void
 */
void AHB_Logic(boolean_T auto_mode, boolean_T ahb_switch, boolean_T low_beam_on,
               double speed, double lux, boolean_T vehicle_detected,
               boolean_T cam_ok, boolean_T manual_override,
               boolean_T *high_beam, unsigned char *ahb_state)
{
  int b_st;
  boolean_T avail;
  /*  --- Hysteresis de vitesse (REQ-LSC-13) : ON a 40 km/h, OFF sous 30 km/h */
  spd_ok = ((speed >= 40.0) || ((!(speed < 30.0)) && spd_ok));
  /*  --- Conditions de disponibilite (REQ-LSC-10) */
  if (auto_mode && ahb_switch && low_beam_on && spd_ok && (lux < 50.0)) {
    avail = true;
  } else {
    avail = false;
  }
  if (!cam_ok) {
    /*  camera en defaut -> etat sur (REQ-LSC-14) */
    hb = false;
    clear_cnt = 0.0;
    b_st = 4;
  } else if (manual_override) {
    /*  le conducteur est prioritaire (REQ-LSC-15) */
    hb = false;
    clear_cnt = 0.0;
    b_st = 3;
  } else if (!avail) {
    /*  conditions non reunies */
    hb = false;
    clear_cnt = 0.0;
    b_st = 0;
  } else if (vehicle_detected) {
    /*  usager detecte -> croisement immediat (REQ-LSC-11) */
    hb = false;
    clear_cnt = 0.0;
    b_st = 1;
  } else {
    /*  route libre : confirmation pendant T_REARM (REQ-LSC-12) */
    clear_cnt = minimum2(clear_cnt + 0.01, 100.0);
    hb = ((clear_cnt > 2.005) || hb);
    if (hb) {
      b_st = 2;
    } else {
      b_st = 1;
    }
  }
  *high_beam = hb;
  *ahb_state = (unsigned char)b_st;
}

/*
 * B3 - Auto High Beam (AHB) : feux de route automatiques
 *  ahb_state : 0 = OFF (non disponible), 1 = READY (disponible, route non
 * libre) 2 = ACTIVE (feux de route), 3 = PAUSE (action manuelle), 4 = FAULT
 * (camera)
 *
 * Arguments    : void
 * Return Type  : void
 */
void AHB_Logic_init(void)
{
  spd_ok = false;
  clear_cnt = 0.0;
  hb = false;
}

/*
 * File trailer for AHB_Logic.c
 *
 * [EOF]
 */
