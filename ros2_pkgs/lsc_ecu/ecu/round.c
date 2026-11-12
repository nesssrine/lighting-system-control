/*
 * File: round.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "round.h"
#include "round1.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * Arguments    : double x[8]
 * Return Type  : void
 */
void b_round(double x[8])
{
  int k;
  for (k = 0; k < 8; k++) {
    c_round(&x[k]);
  }
}

/*
 * File trailer for round.c
 *
 * [EOF]
 */
