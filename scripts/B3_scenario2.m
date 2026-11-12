%% B3 - Scenario 2 : defaut camera, action manuelle, retour du jour (40 s)
t = (0:Ts:40)';  on = true(size(t));
cam = on;  cam(t >= 10 & t < 15) = false;     % camera en defaut 10-15 s
man = ~on; man(t >= 25 & t < 27) = true;      % appel de phares 25-27 s
lx  = 10*ones(size(t)); lx(t >= 33) = 5000;   % le jour revient a 33 s
autoSig  = timeseries(on,t);  switchSig = timeseries(on,t);  lowSig = timeseries(on,t);
speedSig = timeseries(80*ones(size(t)),t);    luxSig = timeseries(lx,t);
detSig   = timeseries(~on,t); camSig = timeseries(cam,t);    manSig = timeseries(man,t);
disp('Scenario 2 pret : defaut camera 10-15 s, appel de phares 25-27 s, jour a 33 s.')
