% Copie le code de B2_logic.txt dans le bloc MATLAB Function du modele B2_manuel
rt = sfroot;
ch = rt.find('-isa','Stateflow.EMChart','Path','B2_manuel/MATLAB Function');
ch.Script = fileread(which('B2_logic.txt'));
disp('Code colle dans le bloc MATLAB Function.')
