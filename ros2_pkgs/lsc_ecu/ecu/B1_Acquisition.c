/*
 * File: B1_Acquisition.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "B1_Acquisition.h"
#include "minOrMax.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static boolean_T init_not_empty;

static boolean_T valid;

static double absent_cnt;

static double good_cnt;

static double sw_cnt;

static double fl_cnt;

/* Function Definitions */
/*
 * B1 - Acquisition et filtrage des entrees
 *    lux_raw   : mesure brute du capteur de luminosite [lux]
 *    msg_ok    : 1 si le message du capteur est recu a ce pas (bus CAN)
 *    sw_raw    : position brute du commodo (0 OFF, 1 AUTO, 2 POSITION, 3
 * CROISEMENT) flash_raw : contact brut du levier d'appel de phares
 *
 * Arguments    : double lux_raw
 *                boolean_T msg_ok
 *                double sw_raw
 *                boolean_T flash_raw
 *                double *lux_filt
 *                boolean_T *lux_valid
 *                double *sw_pos
 *                boolean_T *flash_req
 * Return Type  : void
 */
void B1_Acquisition(double lux_raw, boolean_T msg_ok, double sw_raw,
                    boolean_T flash_raw, double *lux_filt, boolean_T *lux_valid,
                    double *sw_pos, boolean_T *flash_req)
{
  static double sw_last;
  static double sw_out;
  static double yf;
  static boolean_T fl_last;
  static boolean_T fl_out;
  boolean_T in_range;
  if (!init_not_empty) {
    init_not_empty = true;
    yf = lux_raw;
    sw_last = sw_raw;
    sw_out = sw_raw;
    fl_last = flash_raw;
    fl_out = flash_raw;
  }
  /*  ---------- 1) Diagnostic du capteur de luminosite (REQ-LSC-09) */
  if ((lux_raw >= 0.0) && (lux_raw <= 100000.0)) {
    in_range = true;
  } else {
    in_range = false;
  }
  if (msg_ok) {
    absent_cnt = 0.0;
  } else {
    absent_cnt = minimum2(absent_cnt + 0.01, 100.0);
  }
  /*  message absent depuis plus de 500 ms */
  if ((!in_range) || (absent_cnt > 0.505)) {
    valid = false;
    good_cnt = 0.0;
    /*  defaut detecte immediatement */
  } else if (msg_ok) {
    good_cnt = minimum2(good_cnt + 0.01, 100.0);
    if (good_cnt > 1.005) {
      /*  retour a la normale apres 1 s de mesures correctes */
      valid = true;
    }
  }
  /*  ---------- 2) Filtre passe-bas du 1er ordre (NFR-04), fige si mesure non
   * fiable */
  if (in_range && msg_ok) {
    if (lux_raw < 0.2 * yf) {
      /*  chute brutale > 80 % (entree de tunnel) : */
      yf = lux_raw;
      /*  suivi immediat, sinon le filtre retarde B2 (REQ-LSC-08) */
    } else {
      yf += 0.047619047619047616 * (lux_raw - yf);
    }
  }
  /*  ---------- 3) Anti-rebond du commodo (NFR-04 / REQ-LSC-02) */
  if (sw_raw != sw_last) {
    sw_last = sw_raw;
    sw_cnt = 0.0;
    /*  la position bouge : on recommence */
  } else {
    sw_cnt = minimum2(sw_cnt + 0.01, 100.0);
    if (sw_cnt > 0.045000000000000005) {
      sw_out = sw_raw;
      /*  stable depuis 50 ms : on valide */
    }
  }
  /*  ---------- 4) Anti-rebond de l'appel de phares */
  if (flash_raw != fl_last) {
    fl_last = flash_raw;
    fl_cnt = 0.0;
  } else {
    fl_cnt = minimum2(fl_cnt + 0.01, 100.0);
    if (fl_cnt > 0.045000000000000005) {
      fl_out = flash_raw;
    }
  }
  *lux_filt = yf;
  *lux_valid = valid;
  *sw_pos = sw_out;
  *flash_req = fl_out;
}

/*
 * B1 - Acquisition et filtrage des entrees
 *    lux_raw   : mesure brute du capteur de luminosite [lux]
 *    msg_ok    : 1 si le message du capteur est recu a ce pas (bus CAN)
 *    sw_raw    : position brute du commodo (0 OFF, 1 AUTO, 2 POSITION, 3
 * CROISEMENT) flash_raw : contact brut du levier d'appel de phares
 *
 * Arguments    : void
 * Return Type  : void
 */
void B1_Acquisition_init(void)
{
  valid = true;
  absent_cnt = 0.0;
  good_cnt = 0.0;
  sw_cnt = 0.0;
  fl_cnt = 0.0;
}

/*
 * Arguments    : void
 * Return Type  : void
 */
void init_not_empty_init(void)
{
  init_not_empty = false;
}

/*
 * File trailer for B1_Acquisition.c
 *
 * [EOF]
 */
