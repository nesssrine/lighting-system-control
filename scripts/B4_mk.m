%% B4 - fabrique les 11 signaux d'entree a partir des variables du scenario
ignSig = timeseries(ign,t);   swSig  = timeseries(sw,t);    flSig  = timeseries(fl,t);
hbSig  = timeseries(hb,t);    fogSig = timeseries(fg,t);    alSig  = timeseries(al,t);
ahbSig = timeseries(ah,t);    luxSig = timeseries(lx,t);    batSig = timeseries(vb,t);
doorSig = timeseries(dc,t);   degSig = timeseries(dg,t);
