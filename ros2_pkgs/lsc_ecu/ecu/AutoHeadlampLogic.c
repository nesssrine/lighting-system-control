/*
 * File: AutoHeadlampLogic.c
 *
 * MATLAB Coder version            : 5.5
 * C/C++ source code generated on  : 08-Nov-2026 23:08:12
 */

/* Include Files */
#include "AutoHeadlampLogic.h"
#include "mod.h"
#include "rt_nonfinite.h"

/* Variable Definitions */
static boolean_T st;

static double cnt;

static double buf[50];

static double idx;

/* Function Definitions */
/*
 * B2 - Auto Headlamp : allumage/extinction automatique avec hysteresis
 *
 * Arguments    : double lux
 *                boolean_T auto_mode
 *                boolean_T lux_valid
 * Return Type  : boolean_T
 */
boolean_T AutoHeadlampLogic(double lux, boolean_T auto_mode,
                            boolean_T lux_valid)
{
  double lux_past;
  boolean_T tunnel;
  /*  memoire conservee d'un pas a l'autre */
  /*  50 x 10 ms = 0,5 s d'historique */
  /*  --- Detection tunnel : chute > 80 % en 0,5 s */
  lux_past = buf[(int)idx - 1];
  buf[(int)idx - 1] = lux;
  idx = b_mod(idx) + 1.0;
  if ((lux < 0.2 * lux_past) && (lux < 1000.0)) {
    tunnel = true;
  } else {
    tunnel = false;
  }
  /*  --- Logique principale */
  if (!auto_mode) {
    st = false;
    cnt = 0.0;
    /*  pas en AUTO : B2 ne demande rien */
  } else if (!lux_valid) {
    st = true;
    cnt = 0.0;
    /*  capteur en defaut : etat sur */
  } else if (!st) {
    /*  feux eteints */
    if (lux < 1000.0) {
      cnt += 0.01;
      if ((cnt > 2.005) || (tunnel && (cnt > 0.305))) {
        st = true;
        cnt = 0.0;
      }
    } else {
      cnt = 0.0;
      /*  condition interrompue -> on recommence */
    }

    /*  feux allumes */
  } else if (lux > 2000.0) {
    cnt += 0.01;
    if (cnt > 5.005) {
      st = false;
      cnt = 0.0;
    }
  } else {
    cnt = 0.0;
  }
  return st;
}

/*
 * B2 - Auto Headlamp : allumage/extinction automatique avec hysteresis
 *
 * Arguments    : void
 * Return Type  : void
 */
void AutoHeadlampLogic_init(void)
{
  int i;
  /*  initialisation au 1er pas */
  st = false;
  cnt = 0.0;
  for (i = 0; i < 50; i++) {
    buf[i] = 10000.0;
  }
  idx = 1.0;
}

/*
 * File trailer for AutoHeadlampLogic.c
 *
 * [EOF]
 */
