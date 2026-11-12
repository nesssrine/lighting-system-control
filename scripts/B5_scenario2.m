%% B5 - Scenario 2 : feux stop, freinage d'urgence (ESS), detresse automatique (30 s)
t = (0:Ts:30)';  F = false(size(t));
spd = 40*ones(size(t));
spd(t >= 8 & t < 9.5) = 40 + (t(t >= 8 & t < 9.5) - 8) * (50/1.5);   % acceleration 40 -> 90 km/h
spd(t >= 9.5) = 90;
i = t >= 10;  spd(i) = max(90 - 28.8*(t(i) - 10), 0);                % freinage 8 m/s2 -> arret a 13,125 s
i = t >= 22;  spd(i) = min(7.5*(t(i) - 22), 30);                     % redemarrage
dec = zeros(size(t));
dec(t >= 2 & t < 4) = 2;                                             % freinage normal
dec(t >= 5 & t < 6) = 7;                                             % freinage fort mais a 40 km/h
dec(t >= 10 & t < 13.125) = 8;                                       % freinage d'urgence a 90 km/h
br = F; br(t >= 2 & t < 4) = true; br(t >= 5 & t < 6) = true; br(t >= 10 & t < 20) = true;
ignSig = timeseries(true(size(t)),t); tlSig = timeseries(F,t); trSig = timeseries(F,t); hzSig = timeseries(F,t);
brSig = timeseries(br,t); spdSig = timeseries(spd,t); decSig = timeseries(dec,t);
fLSig = timeseries(F,t); fRSig = timeseries(F,t);
disp('Scenario 2 pret : freinage normal 2 s, fort a 40 km/h 5 s, urgence a 90 km/h 10 s.')
