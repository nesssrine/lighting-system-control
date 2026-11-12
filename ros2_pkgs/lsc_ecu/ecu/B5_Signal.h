/*
 * File: B5_Signal.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef B5_SIGNAL_H
#define B5_SIGNAL_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void B5_Signal(boolean_T ignition, boolean_T turn_left, boolean_T turn_right,
               boolean_T hazard_sw, boolean_T brake_pedal, double speed,
               double decel, boolean_T fault_L, boolean_T fault_R,
               boolean_T *blink_L, boolean_T *blink_R, boolean_T *brake_light,
               boolean_T *hazard_active, boolean_T *ess_active);

void B5_Signal_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for B5_Signal.h
 *
 * [EOF]
 */
