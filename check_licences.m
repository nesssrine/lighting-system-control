% Verifie licence + installation des toolboxes necessaires au projet
f = fopen('results\licences.txt','w');
noms = {'Stateflow','Simulink Coder','Simulink Test','Simulink Coverage','Simulink Check','Embedded Coder','MATLAB Coder'};
cles = {'Stateflow','Real-Time_Workshop','Simulink_Test','Simulink_Coverage','SL_Verification_Validation','RTW_Embedded_Coder','MATLAB_Coder'};
v = ver; installes = {v.Name};
fprintf(f,'Licence: %s\n', license);
for k = 1:numel(noms)
    fprintf(f,'%-20s licence=%d  installe=%d\n', noms{k}, license('test',cles{k}), any(strcmp(installes,noms{k})));
end
fclose(f);
