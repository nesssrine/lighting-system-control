/*
 * File: B4_Manager.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "B4_Manager.h"
#include "minOrMax.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static boolean_T b_init_not_empty;

static boolean_T fmh;

static double b_rem;

static double tot;

static double t_off;

static boolean_T hb_man;

static boolean_T fog_st;

/* Function Definitions */
/*
 * B4 - Lighting Manager (arbitrage des feux avant) + B8 - Follow-me-home
 *  sw_pos : 0 OFF, 1 AUTO, 2 POSITION, 3 CROISEMENT      degraded (B6) : 0
 * aucun, 1 G, 2 D, 3 les deux
 *
 * Arguments    : boolean_T ignition
 *                double sw_pos
 *                boolean_T flash
 *                boolean_T hb_toggle
 *                boolean_T fog_sw
 *                boolean_T auto_low
 *                boolean_T ahb_req
 *                double lux
 *                double vbat
 *                boolean_T door_closed
 *                unsigned char degraded
 *                boolean_T *low_L
 *                boolean_T *low_R
 *                boolean_T *high
 *                boolean_T *position
 *                boolean_T *drl
 *                boolean_T *fog
 *                boolean_T *fmh_active
 *                unsigned char *light_state
 * Return Type  : void
 */
void B4_Manager(boolean_T ignition, double sw_pos, boolean_T flash,
                boolean_T hb_toggle, boolean_T fog_sw, boolean_T auto_low,
                boolean_T ahb_req, double lux, double vbat,
                boolean_T door_closed, unsigned char degraded, boolean_T *low_L,
                boolean_T *low_R, boolean_T *high, boolean_T *position,
                boolean_T *drl, boolean_T *fog, boolean_T *fmh_active,
                unsigned char *light_state)
{
  static double p_sw;
  static boolean_T p_flash;
  static boolean_T p_fog;
  static boolean_T p_hb;
  static boolean_T p_ign;
  boolean_T bat_ok;
  boolean_T fl_rise;
  boolean_T fog_rise;
  boolean_T guard1 = false;
  boolean_T hb_rise;
  if (!b_init_not_empty) {
    b_init_not_empty = true;
    p_ign = ignition;
    p_flash = flash;
    p_hb = hb_toggle;
    p_fog = fog_sw;
    p_sw = sw_pos;
  }
  if (flash && (!p_flash)) {
    fl_rise = true;
  } else {
    fl_rise = false;
  }
  if (hb_toggle && (!p_hb)) {
    hb_rise = true;
  } else {
    hb_rise = false;
  }
  if (fog_sw && (!p_fog)) {
    fog_rise = true;
  } else {
    fog_rise = false;
  }
  bat_ok = (vbat >= 11.8);
  /*  =============== B8 : FOLLOW-ME-HOME =============== */
  if (p_ign && (!ignition)) {
    /*  le conducteur coupe le contact */
    t_off = 0.0;
    if ((sw_pos == 1.0) && (lux < 1000.0) && bat_ok) {
      /*  activation automatique (REQ-LSC-25, 31) */
      fmh = true;
      tot = 30.0;
      b_rem = 30.0;
    }
  }
  if (!ignition) {
    t_off = minimum2(t_off + 0.01, 1000.0);
  }
  if (fl_rise && (!ignition) && bat_ok && ((t_off <= 10.0) || fmh)) {
    if (!fmh) {
      fmh = true;
      tot = 0.0;
      b_rem = 0.0;
    }
    /*  activation manuelle (REQ-LSC-27) */
    tot = minimum2(tot + 30.0, 120.0);
    /*  prolongation (REQ-LSC-28) */
    b_rem = minimum2(b_rem + 30.0, 120.0);
  }
  if (fmh) {
    if (!door_closed) {
      b_rem = tot;
      /*  porte ouverte : le compteur repart (REQ-LSC-29) */
    } else {
      b_rem -= 0.01;
    }
    fmh = !(b_rem <= -0.005);
    /*  duree ecoulee (compteur passe sous 0) : extinction */
  }
  if ((ignition && (!p_ign)) ||
      ((sw_pos != p_sw) && ((sw_pos == 0.0) || (sw_pos == 2.0))) || (!bat_ok)) {
    fmh = false;
    /*  annulation (REQ-LSC-30) */
  }
  /*  =============== B4 : ARBITRAGE =============== */
  if (fmh) {
    /*  REQ-LSC-32 : croisement + position seulement */
    bat_ok = true;
    *high = false;
    *position = true;
    *drl = false;
    hb_man = false;
    fog_st = false;
  } else if (ignition) {
    if ((sw_pos == 3.0) || ((sw_pos == 1.0) && auto_low)) {
      bat_ok = true;
    } else {
      bat_ok = false;
    }
    /*  manuel ou demande de B2 (REQ-LSC-01, 06) */
    if (bat_ok || (sw_pos == 2.0)) {
      *position = true;
    } else {
      *position = false;
    }
    guard1 = false;
    if (!bat_ok) {
      hb_man = false;
      guard1 = true;
    } else {
      if (hb_rise) {
        hb_man = !hb_man;
        /*  commutation croisement <-> route (REQ-LSC-02) */
      }
      if (hb_man || ((sw_pos == 1.0) && ahb_req)) {
        *high = true;
      } else {
        guard1 = true;
      }
    }
    if (guard1) {
      if (flash) {
        *high = true;
      } else {
        *high = false;
      }
    }
    /*  manuel > AHB ; appel de phares (REQ-LSC-03, 15) */
    if ((!bat_ok) && (sw_pos != 2.0)) {
      *drl = true;
    } else {
      *drl = false;
    }
    /*  DRL (REQ-LSC-05) */
  } else {
    bat_ok = false;
    *high = false;
    *drl = false;
    hb_man = false;
    *position = (sw_pos == 2.0);
    /*  feux de stationnement contact coupe */
  }
  if (!bat_ok) {
    fog_st = false;
    /*  antibrouillard impossible sans croisement (REQ-LSC-04) */
    *low_L = false;
  } else {
    if (fog_rise) {
      fog_st = !fog_st;
    }
    if ((degraded == 1) || (degraded == 3)) {
      *low_L = false;
    } else {
      *low_L = true;
    }
  }
  /*  lampe en defaut : on coupe sa commande (REQ-LSC-24) */
  if (bat_ok && (degraded != 2) && (degraded != 3)) {
    *low_R = true;
  } else {
    *low_R = false;
  }
  if (fog_st && bat_ok) {
    *fog = true;
  } else {
    *fog = false;
  }
  *fmh_active = fmh;
  if (fmh) {
    *light_state = 5U;
  } else if (*high) {
    *light_state = 4U;
  } else if (bat_ok) {
    *light_state = 3U;
  } else if (*position) {
    *light_state = 2U;
  } else {
    *light_state = *drl;
  }
  /*  0 OFF, 1 DRL, 2 POSITION, 3 CROISEMENT, 4 ROUTE, 5 FMH */
  p_ign = ignition;
  p_flash = flash;
  p_hb = hb_toggle;
  p_fog = fog_sw;
  p_sw = sw_pos;
}

/*
 * B4 - Lighting Manager (arbitrage des feux avant) + B8 - Follow-me-home
 *  sw_pos : 0 OFF, 1 AUTO, 2 POSITION, 3 CROISEMENT      degraded (B6) : 0
 * aucun, 1 G, 2 D, 3 les deux
 *
 * Arguments    : void
 * Return Type  : void
 */
void B4_Manager_init(void)
{
  fmh = false;
  b_rem = 0.0;
  tot = 0.0;
  t_off = 100.0;
  hb_man = false;
  fog_st = false;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void b_init_not_empty_init(void)
{
  b_init_not_empty = false;
}

/*
 * File trailer for B4_Manager.c
 *
 * [EOF]
 */
