/*
 * File: B4_Manager.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef B4_MANAGER_H
#define B4_MANAGER_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void B4_Manager(boolean_T ignition, double sw_pos, boolean_T flash,
                boolean_T hb_toggle, boolean_T fog_sw, boolean_T auto_low,
                boolean_T ahb_req, double lux, double vbat,
                boolean_T door_closed, unsigned char degraded, boolean_T *low_L,
                boolean_T *low_R, boolean_T *high, boolean_T *position,
                boolean_T *drl, boolean_T *fog, boolean_T *fmh_active,
                unsigned char *light_state);

void B4_Manager_init(void);

void b_init_not_empty_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for B4_Manager.h
 *
 * [EOF]
 */
