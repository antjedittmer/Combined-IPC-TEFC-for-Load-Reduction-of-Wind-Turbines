function [AnalysePSDout] = AnalysePSD_2(SimRunFolderPath,BaselineCase,BaselineCaseFolderPath,DoOptimization)
%FURTHERPOSTPROCESSING Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('PSD-Analyse wird durchgeführt. \n');
 
if isfile(fullfile(SimRunFolderPath,'Log.text')) == 1
    LoopStart = 4;
else
    LoopStart = 3;
end

 % Wenn Optimisiert wird, pruefen, ob Ordnernamen in SimRunFolderPath und
 % BaselineCaseFolderPath gleich sind
 if DoOptimization == "true"
     folderNamesBaselineCase = dir(BaselineCaseFolderPath);
     if size(folderNames,1) ~= size(folderNamesBaselineCase,1)
         fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
         AnalysePSDout = [];
         return;
     end
     
     for x = LoopStart : length(folderNames)
         if folderNames(x).name ~= folderNamesBaselineCase(x).name
             fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
             AnalysePSDout = [];
             return;
         end
     end
 end

 for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
     switch DoOptimization
         case "false"
             % Daten einlesen
             readBaselineData = 'false';
             [pks, intPSD, BaselineIndex, sheets] = readDataPSD(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
             
             % Funktion Beenden wenn nicht alle Daten eingelesen wurden konnten
             if isempty(pks)
                AnalysePSDout = [];
                return;
             end
             
             % Daten auswerten
             pks_size = size(pks);
             for i = 1 : pks_size(2)
                rel_delta_pks(:,i) = 100*(pks(:,i) - pks(:,BaselineIndex)) ./ pks(:, BaselineIndex);
                rel_delta_intPSD(i) = 100*(intPSD(i) - intPSD(BaselineIndex)) ./ intPSD(BaselineIndex);
             end 

             % Ergebnisse Zusammenfassen
             results.IntegralPSD = intPSD;
             results.RelDeltaP   = rel_delta_pks;
             results.RelDeltaInt = rel_delta_intPSD;
             results.sheets      = sheets(2:end);
             
            
            % Ausgabe der Ergebnisse
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            fprintf('Relative Änderungen in P im Vergleich zum Referenzfall %s:\n', BaselineCase);
            fprintf('-----------------------------');
            rel_delta_pks_size = size(rel_delta_pks);
            for j = 2 : length(sheets)
                fprintf('| %s ', sheets(j));
            end
            fprintf('|\n');

            for k = 1 : rel_delta_pks_size(1)
                fprintf('P%d                           |',k);
                for u = 1 : rel_delta_pks_size(2)
                    fprintf('             %.2f %%            | ',rel_delta_pks(k,u));
                end
                fprintf('\n');
            end

            fprintf('Integral der Leistungsdichte |');
            for u = 1 : rel_delta_pks_size(2)
                fprintf('        %.2f            | ',intPSD(u));
            end
            fprintf('\n');

            fprintf('Relative Änderungen          |');
            for u = 1 : rel_delta_pks_size(2)
                fprintf('             %.2f %%            | ',rel_delta_intPSD(u));
            end
            fprintf('\n');
             
             
         case "true"
             % Daten einlesen
             readBaselineData = 'true';
             [Baseline_pks, Baseline_intPSD, ~, ~] = readDataPSD(BaselineCaseFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
             readBaselineData = 'false';
             [pks, intPSD, ~, sheets] = readDataPSD(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
             
             % Funktion Beenden wenn nicht alle Daten eingelesen wurden konnten
             if isempty(Baseline_pks)
                AnalysePSDout = [];
                return;
             end
             
             % Daten auswerten             
             rel_delta_pks = 100*(pks - Baseline_pks) ./ Baseline_pks;
             rel_delta_intPSD = 100*(intPSD - Baseline_intPSD) ./ Baseline_intPSD;
            
             % Ergebnisse Zusammenfassen
             results.IntegralPSD = intPSD;
             results.RelDeltaP   = rel_delta_pks;
             results.RelDeltaInt = rel_delta_intPSD;
             results.sheets      = sheets(1:end);
                       
            % Ausgabe der Ergebnisse
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Baselinecase-Ordner: %s \n', folderNamesBaselineCase(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            fprintf('Relative Änderungen in P im Vergleich zum Referenzfall %s:\n', BaselineCase);
            fprintf('-----------------------------');
            rel_delta_pks_size = size(rel_delta_pks);
            
            fprintf('| %s ', sheets);            
            fprintf('|\n');

            for k = 1 : rel_delta_pks_size(1)
                fprintf('P%d                           |',k);
                fprintf('             %.2f %%            | ',rel_delta_pks(k));
                fprintf('\n');
            end

            fprintf('Integral der Leistungsdichte |');
            fprintf('        %.2f            | ',intPSD);
            fprintf('\n');
            fprintf('Relative Änderungen          |');
            fprintf('             %.2f %%            | ',rel_delta_intPSD);
            fprintf('\n');
                          
     end
     
     % Erstellen des Outputs
     AnalysePSDout.(sprintf('%s',folderNames(z).name)) = results; 
     
     % Speicher der Ergebnisse als .mat-Datei
     PSDAnalyseResults.(sprintf('%s',folderNames(z).name)) = results; 
     save([SimRunFolderPath filesep folderNames(z).name filesep 'PSDAnalyseResults.mat'], 'PSDAnalyseResults');
     clear PSDAnalyseResults
          
 end
 


end

