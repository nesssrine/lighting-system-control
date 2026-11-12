/*
 * File: round1.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "round1.h"
#include "LSC_ECU_rtwutil.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * Arguments    : double *x
 * Return Type  : void
 */
void c_round(double *x)
{
  *x = rt_roundd_snf(*x);
}

/*
 * File trailer for round1.c
 *
 * [EOF]
 */
