/*
 * File: B7_Driver.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "B7_Driver.h"
#include "LSC_ECU_rtwutil.h"
#include "minOrMax.h"
#include "round.h"
#include "rt_nonfinite.h"
#include "sqrt.h"
#include <string.h>

/* Variable Definitions */
static double ramp[4];

/* Function Definitions */
/*
 * B7 - Pilotage des sorties (PWM)
 *  duty (8 voies, %) : 1 croisement G, 2 croisement D, 3 route, 4 LED avant
 * DRL/veilleuse, 5 clignotant G, 6 clignotant D, 7 LED arriere stop/position, 8
 * antibrouillard AR
 *
 * Arguments    : boolean_T low_L
 *                boolean_T low_R
 *                boolean_T high
 *                boolean_T position
 *                boolean_T drl
 *                boolean_T fog
 *                boolean_T blink_L
 *                boolean_T blink_R
 *                boolean_T brake
 *                double vbat
 *                unsigned char duty[8]
 *                double *veff_low
 *                boolean_T diag_cmd[4]
 * Return Type  : void
 */
void B7_Driver(boolean_T low_L, boolean_T low_R, boolean_T high,
               boolean_T position, boolean_T drl, boolean_T fog,
               boolean_T blink_L, boolean_T blink_R, boolean_T brake,
               double vbat, unsigned char duty[8], double *veff_low,
               boolean_T diag_cmd[4])
{
  double d[8];
  double dv[8];
  double d_reg;
  int i;
  unsigned char u;
  /*  rampes : croisement G, croisement D, route, antibrouillard */
  /*  1) Regulation de tension des lampes halogenes : tension efficace constante
   * = V_EFF */
  d_reg = 13.2 / maximum2(vbat);
  d_reg = minimum2(1.0, d_reg * d_reg);
  /*  Veff = sqrt(duty) * Vbat */
  /*  2) Demarrage progressif (soft-start) : limite le pic de courant du
   * filament froid */
  if (low_L) {
    ramp[0] = minimum2(ramp[0] + 0.099999999999999992, 1.0);
    /*  0 -> 100 % en T_SOFT */
  } else {
    ramp[0] = 0.0;
    /*  extinction immediate */
  }
  if (low_R) {
    ramp[1] = minimum2(ramp[1] + 0.099999999999999992, 1.0);
    /*  0 -> 100 % en T_SOFT */
  } else {
    ramp[1] = 0.0;
    /*  extinction immediate */
  }
  if (high) {
    ramp[2] = minimum2(ramp[2] + 0.099999999999999992, 1.0);
    /*  0 -> 100 % en T_SOFT */
  } else {
    ramp[2] = 0.0;
    /*  extinction immediate */
  }
  if (fog) {
    ramp[3] = minimum2(ramp[3] + 0.099999999999999992, 1.0);
    /*  0 -> 100 % en T_SOFT */
  } else {
    ramp[3] = 0.0;
    /*  extinction immediate */
  }
  memset(&d[0], 0, 8U * sizeof(double));
  d[0] = ramp[0] * d_reg;
  d[1] = ramp[1] * d_reg;
  d[2] = ramp[2] * d_reg;
  d[7] = ramp[3] * d_reg;
  /*  3) LED avant a deux niveaux : DRL plein (100 %), veilleuse attenuee
   * (REQ-LSC-05) */
  if (drl) {
    d[3] = 1.0;
  } else if (position) {
    d[3] = 0.3;
  }
  /*  4) Clignotants : pleine tension regulee des le 1er pas (pas de rampe,
   * flash net) */
  d[4] = (double)blink_L * d_reg;
  d[5] = (double)blink_R * d_reg;
  /*  5) LED arriere a deux niveaux : stop plein, position attenuee */
  if (brake) {
    d[6] = 1.0;
  } else if (position) {
    d[6] = 0.2;
  }
  for (i = 0; i < 8; i++) {
    dv[i] = 100.0 * d[i];
  }
  b_round(dv);
  for (i = 0; i < 8; i++) {
    d_reg = rt_roundd_snf(dv[i]);
    if (d_reg < 256.0) {
      if (d_reg >= 0.0) {
        u = (unsigned char)d_reg;
      } else {
        u = 0U;
      }
    } else if (d_reg >= 256.0) {
      u = MAX_uint8_T;
    } else {
      u = 0U;
    }
    duty[i] = u;
  }
  d_reg = d[0];
  b_sqrt(&d_reg);
  *veff_low = d_reg * vbat;
  /*  tension efficace vue par le croisement gauche */
  diag_cmd[0] = (d[0] > 0.0);
  diag_cmd[1] = (d[1] > 0.0);
  diag_cmd[2] = (d[4] > 0.0);
  diag_cmd[3] = (d[5] > 0.0);
  /*  lampes allumees, pour le diagnostic B6 */
}

/*
 * B7 - Pilotage des sorties (PWM)
 *  duty (8 voies, %) : 1 croisement G, 2 croisement D, 3 route, 4 LED avant
 * DRL/veilleuse, 5 clignotant G, 6 clignotant D, 7 LED arriere stop/position, 8
 * antibrouillard AR
 *
 * Arguments    : void
 * Return Type  : void
 */
void B7_Driver_init(void)
{
  ramp[0] = 0.0;
  ramp[1] = 0.0;
  ramp[2] = 0.0;
  ramp[3] = 0.0;
}

/*
 * File trailer for B7_Driver.c
 *
 * [EOF]
 */
