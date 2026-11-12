%% B1 - Scenario 2 : anti-rebond et constante de temps du filtre (15 s)
t = (0:Ts:15)';
lux = 1000*ones(size(t)); lux(t >= 1) = 2000;              % echelon propre pour mesurer le filtre
msg = true(size(t));
sw = zeros(size(t));                                       % commodo OFF
sw(t >= 2.00 & t < 2.01) = 1; sw(t >= 2.02 & t < 2.03) = 1;% rebonds du contact
sw(t >= 2.03) = 1;                                         % stable en AUTO a partir de 2,03 s
sw(t >= 5.00 & t < 5.02) = 2;                              % parasite de 20 ms vers POSITION
fl = false(size(t));
fl(t >= 8.00 & t < 8.01) = true; fl(t >= 8.02 & t < 8.40) = true;  % appui avec rebond
fl(t >= 10.0 & t < 10.02) = true;                          % parasite de 20 ms
luxRawSig = timeseries(lux, t);  msgSig = timeseries(msg, t);
swSig = timeseries(sw, t);       flashSig = timeseries(fl, t);
disp('Scenario 2 pret : rebonds du commodo a 2 s, parasites a 5 s et 10 s, appel de phares a 8 s.')
