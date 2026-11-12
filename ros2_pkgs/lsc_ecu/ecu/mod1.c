/*
 * File: mod1.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "mod1.h"
#include "rt_nonfinite.h"
#include <math.h>

/* Function Declarations */
static double floatmod(double x);

/* Function Definitions */
/*
 * Arguments    : double x
 * Return Type  : double
 */
static double floatmod(double x)
{
  double r;
  r = fmod(x, 50.0);
  if (r == 0.0) {
    r = 0.0;
  }
  return r;
}

/*
 * Arguments    : double x
 * Return Type  : double
 */
double c_mod(double x)
{
  return floatmod(x);
}

/*
 * File trailer for mod1.c
 *
 * [EOF]
 */
