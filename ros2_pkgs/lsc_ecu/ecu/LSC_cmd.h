/*
 * File: LSC_cmd.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef LSC_CMD_H
#define LSC_CMD_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void
LSC_cmd(boolean_T ignition, double sw_raw, boolean_T flash_raw,
        boolean_T hb_toggle, boolean_T fog_sw, boolean_T ahb_switch,
        boolean_T turn_left, boolean_T turn_right, boolean_T hazard_sw,
        boolean_T brake_pedal, double lux_raw, boolean_T msg_ok, double speed,
        double decel, boolean_T vehicle_detected, boolean_T cam_ok,
        boolean_T door_closed, double vbat, const boolean_T fault_prev[4],
        unsigned char degraded_prev, unsigned char duty[8], double *veff_low,
        boolean_T diag_cmd[4], unsigned char *light_state,
        boolean_T *fmh_active, unsigned char *ahb_state,
        boolean_T *hazard_active, boolean_T *ess_active, double *lux_filt);

void LSC_cmd_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for LSC_cmd.h
 *
 * [EOF]
 */
