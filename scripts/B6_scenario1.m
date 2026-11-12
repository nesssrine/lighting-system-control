%% B6 - Scenario 1 : pannes de lampes (20 s)
% Lampes : 1 croisement G, 2 croisement D, 3 clignotant G, 4 clignotant D
t = (0:Ts:20)';  N = numel(t);
cmd = false(N,4);
cmd(t >= 1, 1:2) = true;                                     % feux de croisement allumes a 1 s
P = 1/1.5;  cmd(:,3) = (t >= 2) & (mod(t - 2 + 1e-9, P) < P/2);  % clignotant G a 1,5 Hz des 2 s
rng(3);
cur = repmat(I_NOM', N, 1) .* (1 + 0.03*randn(N,4)) .* cmd;  % courant nominal + bruit 3 %
ton = zeros(1,4);
for k = 1:N                                                  % pic d'allumage (filament froid) : x8 pendant 30 ms
    ton = (ton + Ts) .* cmd(k,:);
    cur(k, ton > 0 & ton <= 0.03 + 1e-9) = 8 * I_NOM(ton > 0 & ton <= 0.03 + 1e-9)';
end
cur(t >= 3.00 & t < 3.06, 1) = 0;                            % micro-coupure 60 ms (vibration du connecteur)
cur(t >= 5 & t < 15, 2) = 0;                                 % croisement D grille de 5 a 15 s (puis repare)
cur(t >= 9, 3) = 0;                                          % clignotant G grille a 9 s
cur(t >= 12, 1) = 2 * cur(t >= 12, 1);                       % court-circuit partiel sur croisement G a 12 s
clr = false(N,1); clr(t >= 18 & t < 18.05) = true;           % effacement des DTC par le garagiste a 18 s
cmdSig = timeseries(cmd, t);  curSig = timeseries(cur, t);  clrSig = timeseries(clr, t);
figure('Color','w');
for i = 1:4
    subplot(4,1,i); plot(t, cur(:,i), 'LineWidth', 1); grid on; ylim([0 10]);
    ylabel({'Courant [A]', sprintf('lampe %d', i)});
end
subplot(4,1,1); title('Scenario 1 - courants mesures (1 croisement G, 2 croisement D, 3 clignotant G, 4 clignotant D)');
xlabel('Temps [s]');
disp('Scenario 1 pret : cmdSig, curSig, clrSig dans le Workspace.')
