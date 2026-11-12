%% B8 - Scenario 3 : follow-me-home manuel de jour (110 s)
t = (0:Ts:110)';  F = false(size(t));  T = true(size(t));
ign = t < 2;                                            % contact coupe a 2 s, en plein jour
sw = ones(size(t)); dc = T; al = F; ah = F;
lx = 5000*ones(size(t)); vb = 13.5*ones(size(t));
fl = F; for tp = [4 4.5 5 100], fl(t >= tp & t < tp + 0.2) = true; end   % 3 appels de phares, puis un 4e trop tard
hb = F; fg = F; dg = zeros(size(t));
B4_mk;
disp('Scenario 3 pret : 3 appels de phares a 4 / 4,5 / 5 s, un 4e a 100 s.')
