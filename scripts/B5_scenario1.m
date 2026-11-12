%% B5 - Scenario 1 : clignotants, mode autoroute, hyper-clignotement, detresse (20 s)
t = (0:Ts:20)';  F = false(size(t));
ign = true(size(t)); ign(t >= 17) = false;             % contact coupe a 17 s
tl = F; tl(t >= 1 & t < 5) = true;                     % levier gauche maintenu 1-5 s
tl(t >= 12 & t < 16) = true;                           % levier gauche 12-16 s (lampe gauche grillee)
tl(t >= 18 & t < 19) = true;                           % levier gauche pendant la detresse
tr = F; tr(t >= 7 & t < 7.2) = true;                   % impulsion courte a droite (0,2 s)
hz = F; hz(t >= 17) = true;                            % bouton detresse a 17 s
fL = F; fL(t >= 12 & t < 16) = true;                   % lampe clignotant gauche grillee
ignSig = timeseries(ign,t); tlSig = timeseries(tl,t); trSig = timeseries(tr,t); hzSig = timeseries(hz,t);
brSig = timeseries(F,t); spdSig = timeseries(30*ones(size(t)),t); decSig = timeseries(zeros(size(t)),t);
fLSig = timeseries(fL,t); fRSig = timeseries(F,t);
figure('Color','w');
stairs(t, double(tl)+3.6,'b','LineWidth',1.2); hold on; stairs(t, double(tr)+2.4,'r','LineWidth',1.2);
stairs(t, double(hz)+1.2,'Color',[0.9 0.5 0],'LineWidth',1.2); stairs(t, double(fL),'k','LineWidth',1.2);
yticks([0.5 1.7 2.9 4.1]); yticklabels({'Lampe G grillee','Detresse','Levier droit','Levier gauche'});
grid on; xlabel('Temps [s]'); title('Scenario 1 - commandes du conducteur');
disp('Scenario 1 pret : 9 signaux dans le Workspace.')
