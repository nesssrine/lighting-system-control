/*
 * File: minOrMax.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "minOrMax.h"
#include "rt_nonfinite.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * Arguments    : double x
 * Return Type  : double
 */
double maximum2(double x)
{
  double ex;
  if (x >= 1.0) {
    ex = x;
  } else {
    ex = 1.0;
  }
  return ex;
}

/*
 * Arguments    : double x
 *                double y
 * Return Type  : double
 */
double minimum2(double x, double y)
{
  double ex;
  if ((x <= y) || rtIsNaN(y)) {
    ex = x;
  } else {
    ex = y;
  }
  return ex;
}

/*
 * File trailer for minOrMax.c
 *
 * [EOF]
 */
