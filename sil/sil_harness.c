/* Banc de test SIL : execute le code C genere du calculateur (LSC_cmd + LSC_diag)
   pas a pas sur un scenario et compare chaque sortie au resultat MIL (MATLAB). */
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include "LSC_cmd.h"
#include "LSC_diag.h"
#include "Plant_Lamps.h"
#include "LSC_ECU_initialize.h"
#define NIN 24
#define NOUT 22
int main(int argc, char **argv){
  FILE *fi = fopen(argv[1], "r"), *fm = fopen(argv[2], "r"), *fo = fopen(argv[3], "w");
  double u[NIN], ym[NOUT], ys[NOUT]; long n = 0, nd = 0; int i; double maxlux = 0;
  boolean_T fp[4] = {0,0,0,0}; unsigned char dp = 0; long dcount[NOUT] = {0};
  LSC_ECU_initialize();
  while (1) {
    for (i = 0; i < NIN; i++) if (fscanf(fi, "%lf,", &u[i]) != 1) goto fin;
    for (i = 0; i < NOUT; i++) fscanf(fm, "%lf,", &ym[i]);
    { /* u[0] = temps, u[1..23] = 23 entrees */
      unsigned char duty[8], lst, ahb, deg; double veff, lux, cur[4], lf[4];
      boolean_T dcmd[4], fmh, haz, ess, fa[4], wn; unsigned short dtc;
      LSC_cmd(u[1]!=0, u[2], u[3]!=0, u[4]!=0, u[5]!=0, u[6]!=0, u[7]!=0, u[8]!=0, u[9]!=0, u[10]!=0,
              u[11], u[12]!=0, u[13], u[14], u[15]!=0, u[16]!=0, u[17]!=0, u[18], fp, dp,
              duty, &veff, dcmd, &lst, &fmh, &ahb, &haz, &ess, &lux);
      for (i = 0; i < 4; i++) lf[i] = u[20+i];
      Plant_Lamps(duty, u[18], lf, cur);                 /* environnement : courant des lampes */
      LSC_diag(dcmd, cur, u[19]!=0, fa, &dtc, &deg, &wn);
      for (i = 0; i < 4; i++) fp[i] = fa[i];             /* RTE : valeurs disponibles au pas suivant */
      dp = deg;
      for (i = 0; i < 8; i++) ys[i] = duty[i];
      ys[8]=lst; ys[9]=fmh; ys[10]=ahb; ys[11]=haz; ys[12]=ess; ys[13]=lux; ys[14]=veff;
      for (i = 0; i < 4; i++) ys[15+i] = fa[i];
      ys[19]=dtc; ys[20]=deg; ys[21]=wn;
    }
    { int bad = 0;
      for (i = 0; i < NOUT; i++) {
        double e = fabs(ys[i]-ym[i]);
        if (i == 13 || i == 14) { double r = e / (fabs(ym[i]) > 1 ? fabs(ym[i]) : 1); if (r > maxlux) maxlux = r; if (r > 1e-12) { bad = 1; dcount[i]++; } }
        else if (e != 0) { bad = 1; dcount[i]++; }
      }
      nd += bad; }
    for (i = 0; i < NOUT; i++) fprintf(fo, i < NOUT-1 ? "%.17g," : "%.17g\n", ys[i]);
    n++;
  }
fin:
  printf("pas=%ld pas_differents=%ld ecart_relatif_max_analogique=%.3g\n", n, nd, maxlux);
  for (i = 0; i < NOUT; i++) if (dcount[i]) printf("  sortie %d : %ld differences\n", i, dcount[i]);
  return nd != 0;
}
