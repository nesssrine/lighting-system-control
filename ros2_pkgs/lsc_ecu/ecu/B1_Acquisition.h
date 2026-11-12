/*
 * File: B1_Acquisition.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef B1_ACQUISITION_H
#define B1_ACQUISITION_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
void B1_Acquisition(double lux_raw, boolean_T msg_ok, double sw_raw,
                    boolean_T flash_raw, double *lux_filt, boolean_T *lux_valid,
                    double *sw_pos, boolean_T *flash_req);

void B1_Acquisition_init(void);

void init_not_empty_init(void);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for B1_Acquisition.h
 *
 * [EOF]
 */
