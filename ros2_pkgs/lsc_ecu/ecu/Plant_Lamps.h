/*
 * File: Plant_Lamps.h
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

#ifndef PLANT_LAMPS_H
#define PLANT_LAMPS_H

/* Include Files */
#include "rtwtypes.h"
#include <stddef.h>
#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function Declarations */
extern void Plant_Lamps(const unsigned char duty[8], double vbat,
                        const double lamp_fail[4], double lamp_cur[4]);

#ifdef __cplusplus
}
#endif

#endif
/*
 * File trailer for Plant_Lamps.h
 *
 * [EOF]
 */
