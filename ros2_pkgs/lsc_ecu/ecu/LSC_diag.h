/*
 * File: LSC_diag.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef LSC_DIAG_H
#define LSC_DIAG_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void LSC_diag(const boolean_T lamp_cmd[4], const double lamp_cur[4],
                     boolean_T clear_dtc, boolean_T fault_act[4],
                     unsigned short *dtc_stored, unsigned char *degraded,
                     boolean_T *warning);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for LSC_diag.h
 *
 * [EOF]
 */
