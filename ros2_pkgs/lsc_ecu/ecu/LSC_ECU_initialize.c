/*
 * File: LSC_ECU_initialize.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "LSC_ECU_initialize.h"
#include "AHB_Logic.h"
#include "AutoHeadlampLogic.h"
#include "B1_Acquisition.h"
#include "B4_Manager.h"
#include "B5_Signal.h"
#include "B6_Diag.h"
#include "B7_Driver.h"
#include "LSC_ECU_data.h"
#include "LSC_cmd.h"
#include "rt_nonfinite.h"

/* Function Definitions */
/*
 * Arguments    : void
 * Return Type  : void
 */
void LSC_ECU_initialize(void)
{
  rt_InitInfAndNaN();
  b_init_not_empty_init();
  init_not_empty_init();
  LSC_cmd_init();
  B1_Acquisition_init();
  AutoHeadlampLogic_init();
  AHB_Logic_init();
  B4_Manager_init();
  B5_Signal_init();
  B7_Driver_init();
  B6_Diag_init();
  isInitialized_LSC_ECU = true;
}

/*
 * File trailer for LSC_ECU_initialize.c
 *
 * [EOF]
 */
