/*
 * File: LSC_diag.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "LSC_diag.h"
#include "B6_Diag.h"
#include "LSC_ECU_data.h"
#include "LSC_ECU_initialize.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * RUNNABLE 2 (10 ms) du calculateur d'eclairage : B6 diagnostic des lampes
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
void LSC_diag(const boolean_T lamp_cmd[4], const double lamp_cur[4],
              boolean_T clear_dtc, boolean_T fault_act[4],
              unsigned short *dtc_stored, unsigned char *degraded,
              boolean_T *warning)
{
  if (!isInitialized_LSC_ECU) {
    LSC_ECU_initialize();
  }
  B6_Diag(lamp_cmd, lamp_cur, clear_dtc, fault_act, dtc_stored, degraded,
          warning);
}

/*
 * File trailer for LSC_diag.c
 *
 * [EOF]
 */
