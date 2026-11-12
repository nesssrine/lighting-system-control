%% B4/B8 - Scenario 2 : follow-me-home automatique de nuit et annulations (55 s)
t = (0:Ts:55)';  F = false(size(t));  T = true(size(t));
ign = t < 5 | (t >= 42 & t < 44) | (t >= 48 & t < 49); % contact coupe a 5 s, 44 s et 49 s
sw = ones(size(t)); sw(t >= 46 & t < 47) = 2;           % AUTO ; commodo sur POSITION a 46 s
dc = ~(t >= 7 & t < 10);                                % porte ouverte de 7 a 10 s
al = T; ah = T;                                         % nuit : B2 demande le croisement, B3 les feux de route
lx = 100*ones(size(t)); vb = 13.5*ones(size(t)); vb(t >= 52) = 11.5;    % batterie faible a 52 s
fl = F; hb = F; fg = F; dg = zeros(size(t));
B4_mk;
disp('Scenario 2 pret : coupure contact 5 s, porte 7-10 s, annulations 46 s et 52 s.')
