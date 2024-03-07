function [c,ceq] = nonlcon(x,UserInputs)
%NONLCON Summary of this function goes here
%   Detailed explanation goes here

disp(x)
fprintf('\nNonlinear Constraints werden überprüft.\n');
[CostsOut, SimRunFolderPath] = main(UserInputs,x);

% Daten der DELs extrahiren
folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 
if isfile(fullfile(SimRunFolderPath,'Log.text')) == 1
    LoopStart = 4;
else
    LoopStart = 3;
end
 
r = 1;
for z = LoopStart : length(folderNames)                                    % loop über Windtestfälle
     
                % Turm DELs
                AnlyseFolderPath  = [folderNames(z).folder filesep folderNames(z).name];
                AnlyseFolderFiles = dir(AnlyseFolderPath);  
                DELFileStatus = "False";

                % Pruefen, ob DELAnalyseResults.mat in AnlyseFolderPath enthalten
                % ist
                DELFileName = 'DELAnalyseResults.mat';
                T = struct2table(AnlyseFolderFiles);
                NumFiles = height(T);                               
                for ii = 3 : NumFiles                    
                    if strcmp(AnlyseFolderFiles(ii).name, DELFileName)
                        DELFileStatus = "True";                                                
                    end                                       
                end
                                              
                if DELFileStatus == "False"
                    fprintf('Fehler in nonlcon! Die Datei DELAnalyseResults.mat wurde nicht gefunden.\n'); 
                    c = [];
                    ceq = [];
                    return;
                end 
                 
                % Einlesen der Daten
                load([AnlyseFolderPath filesep DELFileName], 'DELAnalyseResults');
                           
                FolderName = convertCharsToStrings((folderNames(z).name));
                DELAnalyseResultsStruc = DELAnalyseResults.(sprintf('%s',FolderName));
                for k = 4 : height(DELAnalyseResultsStruc)
                    DELTurm(k-3,:) = DELAnalyseResultsStruc(k,6).results.RelDeltaMax(1);
                end
                
                DELTurmMax(r) = max(DELTurm);
               
                
                % Lesitungsausgabe
                % Einlesen der Daten
                load([AnlyseFolderPath filesep 'PowerReferenceAnalyseOut.mat'], 'PowerReferenceAnalyseOut');
                
                %PowerDelta(r) = PowerReferenceAnalyseOut.(sprintf('%s',folderNames(z).name)).TEF_on_IPC_on(2);
                PowerT = PowerReferenceAnalyseOut.(sprintf('%s',folderNames(z).name));
                PowerDelta(r) = table2array(PowerT(2,2)) * (-1);
                
                r = r + 1;
              
end


switch UserInputs.Optimization.fmincon.Nebenbedingung
    case "TowerDELs"
        c = max(DELTurmMax);
    case "Power"
        c = max(PowerDelta);
    case "TowerDELs_UND_Power"
        if max(PowerDelta) > 0 || max(DELTurmMax) > 0 
            c = abs(max(PowerDelta) + max(DELTurmMax));
            disp(1)
        elseif max(PowerDelta) > 0 && max(DELTurmMax) > 0 
            c = abs(max(PowerDelta) + max(DELTurmMax));
            disp(2)
        elseif max(PowerDelta) <= 0 && max(DELTurmMax) <= 0 
            c = max(PowerDelta) + max(DELTurmMax);
            disp(3)
        end
end
    
ceq = [];

end

