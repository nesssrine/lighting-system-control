/*
 * File: B7_Driver.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef B7_DRIVER_H
#define B7_DRIVER_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void B7_Driver(boolean_T low_L, boolean_T low_R, boolean_T high,
               boolean_T position, boolean_T drl, boolean_T fog,
               boolean_T blink_L, boolean_T blink_R, boolean_T brake,
               double vbat, unsigned char duty[8], double *veff_low,
               boolean_T diag_cmd[4]);

void B7_Driver_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for B7_Driver.h
 *
 * [EOF]
 */
