/*
 * File: B6_Diag.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "B6_Diag.h"
#include "any.h"
#include "minOrMax.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static double ton[4];

static double tbo[4];

static double tbs[4];

static double tgood[4];

static boolean_T fo[4];

static boolean_T fs[4];

static unsigned short stored;

/* Function Definitions */
/*
 * B6 - Diagnostic des lampes par mesure du courant
 *  Lampes : 1 croisement G, 2 croisement D, 3 clignotant G, 4 clignotant D
 *  dtc_stored : bits 0-3 = circuit ouvert (lampe grillee), bits 4-7 =
 * court-circuit
 *
 * Arguments    : const boolean_T lamp_cmd[4]
 *                const double lamp_cur[4]
 *                boolean_T clear_dtc
 *                boolean_T fault_act[4]
 *                unsigned short *dtc_stored
 *                unsigned char *degraded
 *                boolean_T *warning
 * Return Type  : void
 */
void B6_Diag(const boolean_T lamp_cmd[4], const double lamp_cur[4],
             boolean_T clear_dtc, boolean_T fault_act[4],
             unsigned short *dtc_stored, unsigned char *degraded,
             boolean_T *warning)
{
  double d;
  double r;
  boolean_T bad_open;
  boolean_T bad_short;
  if (lamp_cmd[0]) {
    ton[0] = minimum2(ton[0] + 0.01, 100.0);
    /*  temps depuis l'allumage */
  } else {
    ton[0] = 0.0;
  }
  if (lamp_cmd[0] && (ton[0] > 0.055)) {
    /*  on ne juge qu'apres le pic d'allumage */
    r = lamp_cur[0] / 4.1;
    /*  courant mesure / courant nominal */
    bad_open = (r < 0.2);
    /*  < 20 % : lampe grillee (REQ-LSC-22) */
    bad_short = (r > 1.5);
    /*  > 150 % : court-circuit (REQ-LSC-22) */
    if (bad_open) {
      r = tbo[0] + 0.01;
      tbo[0] += 0.01;
    } else {
      r = 0.0;
      tbo[0] = 0.0;
    }
    if (bad_short) {
      d = tbs[0] + 0.01;
      tbs[0] += 0.01;
    } else {
      d = 0.0;
      tbs[0] = 0.0;
    }
    if (r > 0.10500000000000001) {
      /*  confirmation 100 ms */
      fo[0] = true;
      stored |= 1;
    }
    if (d > 0.10500000000000001) {
      fs[0] = true;
      stored = (unsigned short)(stored | 16);
    }
    if ((!bad_open) && (!bad_short)) {
      /*  mesure correcte : guerison */
      tgood[0] = minimum2(tgood[0] + 0.01, 100.0);
      if (tgood[0] > 1.005) {
        fo[0] = false;
        fs[0] = false;
        /*  defaut plus actif (le DTC reste memorise) */
      }
    } else {
      tgood[0] = 0.0;
    }
  } else {
    tbo[0] = 0.0;
    tbs[0] = 0.0;
    /*  lampe eteinte : on ne peut pas juger */
  }
  fault_act[0] = (fo[0] || fs[0]);
  if (lamp_cmd[1]) {
    ton[1] = minimum2(ton[1] + 0.01, 100.0);
    /*  temps depuis l'allumage */
  } else {
    ton[1] = 0.0;
  }
  if (lamp_cmd[1] && (ton[1] > 0.055)) {
    /*  on ne juge qu'apres le pic d'allumage */
    r = lamp_cur[1] / 4.1;
    /*  courant mesure / courant nominal */
    bad_open = (r < 0.2);
    /*  < 20 % : lampe grillee (REQ-LSC-22) */
    bad_short = (r > 1.5);
    /*  > 150 % : court-circuit (REQ-LSC-22) */
    if (bad_open) {
      r = tbo[1] + 0.01;
      tbo[1] += 0.01;
    } else {
      r = 0.0;
      tbo[1] = 0.0;
    }
    if (bad_short) {
      d = tbs[1] + 0.01;
      tbs[1] += 0.01;
    } else {
      d = 0.0;
      tbs[1] = 0.0;
    }
    if (r > 0.10500000000000001) {
      /*  confirmation 100 ms */
      fo[1] = true;
      stored = (unsigned short)(stored | 2);
    }
    if (d > 0.10500000000000001) {
      fs[1] = true;
      stored = (unsigned short)(stored | 32);
    }
    if ((!bad_open) && (!bad_short)) {
      /*  mesure correcte : guerison */
      tgood[1] = minimum2(tgood[1] + 0.01, 100.0);
      if (tgood[1] > 1.005) {
        fo[1] = false;
        fs[1] = false;
        /*  defaut plus actif (le DTC reste memorise) */
      }
    } else {
      tgood[1] = 0.0;
    }
  } else {
    tbo[1] = 0.0;
    tbs[1] = 0.0;
    /*  lampe eteinte : on ne peut pas juger */
  }
  fault_act[1] = (fo[1] || fs[1]);
  if (lamp_cmd[2]) {
    ton[2] = minimum2(ton[2] + 0.01, 100.0);
    /*  temps depuis l'allumage */
  } else {
    ton[2] = 0.0;
  }
  if (lamp_cmd[2] && (ton[2] > 0.055)) {
    /*  on ne juge qu'apres le pic d'allumage */
    r = lamp_cur[2] / 1.6;
    /*  courant mesure / courant nominal */
    bad_open = (r < 0.2);
    /*  < 20 % : lampe grillee (REQ-LSC-22) */
    bad_short = (r > 1.5);
    /*  > 150 % : court-circuit (REQ-LSC-22) */
    if (bad_open) {
      r = tbo[2] + 0.01;
      tbo[2] += 0.01;
    } else {
      r = 0.0;
      tbo[2] = 0.0;
    }
    if (bad_short) {
      d = tbs[2] + 0.01;
      tbs[2] += 0.01;
    } else {
      d = 0.0;
      tbs[2] = 0.0;
    }
    if (r > 0.10500000000000001) {
      /*  confirmation 100 ms */
      fo[2] = true;
      stored = (unsigned short)(stored | 4);
    }
    if (d > 0.10500000000000001) {
      fs[2] = true;
      stored = (unsigned short)(stored | 64);
    }
    if ((!bad_open) && (!bad_short)) {
      /*  mesure correcte : guerison */
      tgood[2] = minimum2(tgood[2] + 0.01, 100.0);
      if (tgood[2] > 1.005) {
        fo[2] = false;
        fs[2] = false;
        /*  defaut plus actif (le DTC reste memorise) */
      }
    } else {
      tgood[2] = 0.0;
    }
  } else {
    tbo[2] = 0.0;
    tbs[2] = 0.0;
    /*  lampe eteinte : on ne peut pas juger */
  }
  fault_act[2] = (fo[2] || fs[2]);
  if (lamp_cmd[3]) {
    ton[3] = minimum2(ton[3] + 0.01, 100.0);
    /*  temps depuis l'allumage */
  } else {
    ton[3] = 0.0;
  }
  if (lamp_cmd[3] && (ton[3] > 0.055)) {
    /*  on ne juge qu'apres le pic d'allumage */
    r = lamp_cur[3] / 1.6;
    /*  courant mesure / courant nominal */
    bad_open = (r < 0.2);
    /*  < 20 % : lampe grillee (REQ-LSC-22) */
    bad_short = (r > 1.5);
    /*  > 150 % : court-circuit (REQ-LSC-22) */
    if (bad_open) {
      r = tbo[3] + 0.01;
      tbo[3] += 0.01;
    } else {
      r = 0.0;
      tbo[3] = 0.0;
    }
    if (bad_short) {
      d = tbs[3] + 0.01;
      tbs[3] += 0.01;
    } else {
      d = 0.0;
      tbs[3] = 0.0;
    }
    if (r > 0.10500000000000001) {
      /*  confirmation 100 ms */
      fo[3] = true;
      stored = (unsigned short)(stored | 8);
    }
    if (d > 0.10500000000000001) {
      fs[3] = true;
      stored = (unsigned short)(stored | 128);
    }
    if ((!bad_open) && (!bad_short)) {
      /*  mesure correcte : guerison */
      tgood[3] = minimum2(tgood[3] + 0.01, 100.0);
      if (tgood[3] > 1.005) {
        fo[3] = false;
        fs[3] = false;
        /*  defaut plus actif (le DTC reste memorise) */
      }
    } else {
      tgood[3] = 0.0;
    }
  } else {
    tbo[3] = 0.0;
    tbs[3] = 0.0;
    /*  lampe eteinte : on ne peut pas juger */
  }
  fault_act[3] = (fo[3] || fs[3]);
  if (clear_dtc) {
    /*  effacement par l'outil de diagnostic */
    stored = 0U;
    if (fo[0]) {
      stored = 1U;
    }
    if (fs[0]) {
      stored = (unsigned short)(stored | 16);
    }
    if (fo[1]) {
      stored = (unsigned short)(stored | 2);
    }
    if (fs[1]) {
      stored = (unsigned short)(stored | 32);
    }
    if (fo[2]) {
      stored = (unsigned short)(stored | 4);
    }
    if (fs[2]) {
      stored = (unsigned short)(stored | 64);
    }
    if (fo[3]) {
      stored = (unsigned short)(stored | 8);
    }
    if (fs[3]) {
      stored = (unsigned short)(stored | 128);
    }
  }
  *dtc_stored = stored;
  *degraded = (unsigned char)(fault_act[0] + (fault_act[1] << 1));
  /*  0 aucun, 1 croisement G, 2 croisement D, 3 les deux (REQ-LSC-24) */
  *warning = any(fault_act);
  /*  temoin defaut au tableau de bord */
}

/*
 * B6 - Diagnostic des lampes par mesure du courant
 *  Lampes : 1 croisement G, 2 croisement D, 3 clignotant G, 4 clignotant D
 *  dtc_stored : bits 0-3 = circuit ouvert (lampe grillee), bits 4-7 =
 * court-circuit
 *
 * Arguments    : void
 * Return Type  : void
 */
void B6_Diag_init(void)
{
  ton[0] = 0.0;
  tbo[0] = 0.0;
  tbs[0] = 0.0;
  tgood[0] = 0.0;
  fo[0] = false;
  fs[0] = false;
  ton[1] = 0.0;
  tbo[1] = 0.0;
  tbs[1] = 0.0;
  tgood[1] = 0.0;
  fo[1] = false;
  fs[1] = false;
  ton[2] = 0.0;
  tbo[2] = 0.0;
  tbs[2] = 0.0;
  tgood[2] = 0.0;
  fo[2] = false;
  fs[2] = false;
  ton[3] = 0.0;
  tbo[3] = 0.0;
  tbs[3] = 0.0;
  tgood[3] = 0.0;
  fo[3] = false;
  fs[3] = false;
  stored = 0U;
}

/*
 * File trailer for B6_Diag.c
 *
 * [EOF]
 */
