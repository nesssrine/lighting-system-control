/*
 * File: any.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "any.h"
#include "allOrAny.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * Arguments    : const boolean_T x[4]
 * Return Type  : boolean_T
 */
boolean_T any(const boolean_T x[4])
{
  return vectorAny(x);
}

/*
 * File trailer for any.c
 *
 * [EOF]
 */
