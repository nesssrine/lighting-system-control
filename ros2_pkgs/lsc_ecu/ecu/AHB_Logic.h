/*
 * File: AHB_Logic.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef AHB_LOGIC_H
#define AHB_LOGIC_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void AHB_Logic(boolean_T auto_mode, boolean_T ahb_switch, boolean_T low_beam_on,
               double speed, double lux, boolean_T vehicle_detected,
               boolean_T cam_ok, boolean_T manual_override,
               boolean_T *high_beam, unsigned char *ahb_state);

void AHB_Logic_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for AHB_Logic.h
 *
 * [EOF]
 */
