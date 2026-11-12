/*
 * File: LSC_cmd.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "LSC_cmd.h"
#include "AHB_Logic.h"
#include "AutoHeadlampLogic.h"
#include "B1_Acquisition.h"
#include "B4_Manager.h"
#include "B5_Signal.h"
#include "B7_Driver.h"
#include "LSC_ECU_data.h"
#include "LSC_ECU_initialize.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static boolean_T low_prev;

/* Function Definitions */
/*
 * RUNNABLE 1 (10 ms) du calculateur d'eclairage : B1 -> B2 -> B3 -> B4/B8 -> B5
 * -> B7 fault_prev et degraded_prev : sorties de LSC_diag au pas precedent
 * (donnees echangees via le RTE)
 *
 * Arguments    : boolean_T ignition
 *                double sw_raw
 *                boolean_T flash_raw
 *                boolean_T hb_toggle
 *                boolean_T fog_sw
 *                boolean_T ahb_switch
 *                boolean_T turn_left
 *                boolean_T turn_right
 *                boolean_T hazard_sw
 *                boolean_T brake_pedal
 *                double lux_raw
 *                boolean_T msg_ok
 *                double speed
 *                double decel
 *                boolean_T vehicle_detected
 *                boolean_T cam_ok
 *                boolean_T door_closed
 *                double vbat
 *                const boolean_T fault_prev[4]
 *                unsigned char degraded_prev
 *                unsigned char duty[8]
 *                double *veff_low
 *                boolean_T diag_cmd[4]
 *                unsigned char *light_state
 *                boolean_T *fmh_active
 *                unsigned char *ahb_state
 *                boolean_T *hazard_active
 *                boolean_T *ess_active
 *                double *lux_filt
 * Return Type  : void
 */
void LSC_cmd(boolean_T ignition, double sw_raw, boolean_T flash_raw,
             boolean_T hb_toggle, boolean_T fog_sw, boolean_T ahb_switch,
             boolean_T turn_left, boolean_T turn_right, boolean_T hazard_sw,
             boolean_T brake_pedal, double lux_raw, boolean_T msg_ok,
             double speed, double decel, boolean_T vehicle_detected,
             boolean_T cam_ok, boolean_T door_closed, double vbat,
             const boolean_T fault_prev[4], unsigned char degraded_prev,
             unsigned char duty[8], double *veff_low, boolean_T diag_cmd[4],
             unsigned char *light_state, boolean_T *fmh_active,
             unsigned char *ahb_state, boolean_T *hazard_active,
             boolean_T *ess_active, double *lux_filt)
{
  double sw_pos;
  boolean_T drl;
  boolean_T flash_req;
  boolean_T fog;
  boolean_T high;
  boolean_T high_beam;
  boolean_T is_auto;
  boolean_T low_L;
  boolean_T low_R;
  boolean_T low_beam;
  boolean_T position;
  if (!isInitialized_LSC_ECU) {
    LSC_ECU_initialize();
  }
  /*  retard d'un pas (Z_low du modele Simulink) */
  B1_Acquisition(lux_raw, msg_ok, sw_raw, flash_raw, lux_filt, &low_beam,
                 &sw_pos, &flash_req);
  is_auto = (sw_pos == 1.0);
  low_beam = AutoHeadlampLogic(*lux_filt, is_auto, low_beam);
  AHB_Logic(is_auto, ahb_switch, low_prev, speed, *lux_filt, vehicle_detected,
            cam_ok, flash_req, &high_beam, ahb_state);
  B4_Manager(ignition, sw_pos, flash_req, hb_toggle, fog_sw, low_beam,
             high_beam, *lux_filt, vbat, door_closed, degraded_prev, &low_L,
             &low_R, &high, &position, &drl, &fog, fmh_active, light_state);
  if (low_L || low_R) {
    low_prev = true;
  } else {
    low_prev = false;
  }
  B5_Signal(ignition, turn_left, turn_right, hazard_sw, brake_pedal, speed,
            decel, fault_prev[2], fault_prev[3], &is_auto, &low_beam,
            &high_beam, hazard_active, ess_active);
  B7_Driver(low_L, low_R, high, position, drl, fog, is_auto, low_beam,
            high_beam, vbat, duty, veff_low, diag_cmd);
}

/*
 * RUNNABLE 1 (10 ms) du calculateur d'eclairage : B1 -> B2 -> B3 -> B4/B8 -> B5
 * -> B7 fault_prev et degraded_prev : sorties de LSC_diag au pas precedent
 * (donnees echangees via le RTE)
 *
 * Arguments    : void
 * Return Type  : void
 */
void LSC_cmd_init(void)
{
  low_prev = false;
}

/*
 * File trailer for LSC_cmd.c
 *
 * [EOF]
 */
