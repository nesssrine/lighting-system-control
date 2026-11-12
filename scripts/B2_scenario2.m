%% B2 - Scenario 2 : defaut capteur en plein jour (10 s a 15 s)
t = (0:Ts:45)';
luxSig = timeseries(5000*ones(size(t)), t);
v = true(size(t));  v(t >= 10 & t < 15) = false;
validSig = timeseries(v, t);
disp('Scenario 2 pret : defaut capteur entre 10 s et 15 s.')
