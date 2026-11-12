#include <stdio.h>
#include "AutoHeadlampLogic.h"
#include "AutoHeadlampLogic_initialize.h"
int main(void){
  FILE*f=fopen("B2_mil.csv","r"); double t,lux,a,v,ym; int n=0,nd=0;
  AutoHeadlampLogic_initialize();
  while(fscanf(f,"%lf,%lf,%lf,%lf,%lf",&t,&lux,&a,&v,&ym)==5){
    boolean_T ys=AutoHeadlampLogic(lux,a!=0,v!=0);
    if((double)ys!=ym){ if(nd<5)printf("diff t=%.2f mil=%g sil=%d\n",t,ym,ys); nd++; }
    n++; }
  printf("pas compares=%d differences=%d\n",n,nd); return nd!=0; }
