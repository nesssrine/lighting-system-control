/*
 * File: Plant_Lamps.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "Plant_Lamps.h"
#include "LSC_ECU_data.h"
#include "LSC_ECU_initialize.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * MODELE DE L'ENVIRONNEMENT (pas du logiciel embarque) : courant moyen consomme
 * par 4 lampes lampes surveillees : voie 1 croisement G, 2 croisement D, 5
 * clignotant G, 6 clignotant D lamp_fail : 1 lampe normale, 0 lampe grillee, 2
 * court-circuit partiel
 *
 * Arguments    : const unsigned char duty[8]
 *                double vbat
 *                const double lamp_fail[4]
 *                double lamp_cur[4]
 * Return Type  : void
 */
void Plant_Lamps(const unsigned char duty[8], double vbat,
                 const double lamp_fail[4], double lamp_cur[4])
{
  double b;
  if (!isInitialized_LSC_ECU) {
    LSC_ECU_initialize();
  }
  b = vbat / 13.5;
  lamp_cur[0] = 4.1 * ((double)duty[0] / 100.0) * b * lamp_fail[0];
  lamp_cur[1] = 4.1 * ((double)duty[1] / 100.0) * b * lamp_fail[1];
  lamp_cur[2] = 1.6 * ((double)duty[4] / 100.0) * b * lamp_fail[2];
  lamp_cur[3] = 1.6 * ((double)duty[5] / 100.0) * b * lamp_fail[3];
}

/*
 * File trailer for Plant_Lamps.c
 *
 * [EOF]
 */
