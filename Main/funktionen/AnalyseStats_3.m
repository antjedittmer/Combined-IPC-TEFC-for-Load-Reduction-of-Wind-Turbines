function [AnalyseStatsout] = AnalyseStats_3(SimRunFolderPath, BaselineCase, BaselineCaseFolderPath, DoOptimization, StatsChannel)
%ANALYSESTATS Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('Statistik-Analyse wird durchgeführt. \n');

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
         AnalyseStatsout = [];
         return;
     end
     
     for x = LoopStart : length(folderNames)
         if folderNames(x).name ~= folderNamesBaselineCase(x).name
             fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
             AnalyseStatsout = [];
             return;
         end
     end
 end

 
 for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle    
     switch DoOptimization
         case "false"
             % Daten einlesen
             readBaselineData = 'false';
             [Data,BaselineIndex,sheets] = readDataStats(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
             
             % Nach Zeile mit gewähltem Channel suchen 
             strarray = convertCharsToStrings(table2array(Data.sheet_1(:,1)));            
             ExcelZeile = strmatch(StatsChannel,strarray,"exact");
             if isempty(ExcelZeile)
                 fprintf('\nDer angegebene Channelname ist in der Analyse_Stats.xls-Datei nicht enthalten.\n');
                 AnalyseStatsout = [];
                 return;
             end

             % Funktion Beenden wenn nicht alle Daten eingelesen wurden konnten
             if isempty(Data)
                AnalyseStatsout = [];
                return;
             end
             
             % Daten auswerten
             for i = 1 : length(fieldnames(Data))
                rel_delta_mean(i)   = 100*(Data.(sprintf('sheet_%d', i)).Mean(ExcelZeile) - Data.(sprintf('sheet_%d', BaselineIndex)).Mean(ExcelZeile) ) ./ Data.(sprintf('sheet_%d', BaselineIndex)).Mean(ExcelZeile);
                rel_delta_StdDev(i) = 100*(Data.(sprintf('sheet_%d', i)).StdDev(ExcelZeile) - Data.(sprintf('sheet_%d', BaselineIndex)).StdDev(ExcelZeile) ) ./ Data.(sprintf('sheet_%d', BaselineIndex)).StdDev(ExcelZeile);
             end 
             
             % Ergebnisse Zusammenfassen
             results.RelDeltaMean   = rel_delta_mean;
             results.RelDeltaStdDev = rel_delta_StdDev;
             results.sheets         = sheets(2:end);
             
             % Ausgabe der Ergebnisse
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);

            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            fprintf('Relative Änderungen des Mittelwerts und der Standardabweichung im Vergleich zum Referenzfall %s:\n', BaselineCase);
            fprintf('------------------------------------');
             
            for j = 1 : length(fieldnames(Data))
               fprintf('| %s ', sheets(j+1));
            end
            fprintf('|\n');
            fprintf('Änderungen der Mittelwerte          |');
            for k = 1 : length(rel_delta_mean)
                fprintf('             %.2f %%            | ',rel_delta_mean(k));
            end
            fprintf('\nÄnderungen der Standardabweichungen |');    
            for k = 1 : length(rel_delta_StdDev)
                fprintf('             %.2f %%            | ',rel_delta_StdDev(k));
            end
            fprintf('\n');
             
            
         case "true"
             % Daten einlesen
             readBaselineData = 'true';
             [DataBaseline,~,~] = readDataStats(BaselineCaseFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
             readBaselineData = 'false';
             [Data,~,sheets] = readDataStats(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
            
             % Nach Zeile mit gewähltem Channel suchen 
             strarray = convertCharsToStrings(table2array(Data.sheet_1(:,1)));            
             ExcelZeile = strmatch(StatsChannel,strarray,"exact");
             if ExcelZeile == 0
                 fprintf('\nDer angegebene Channelname ist in der Analyse_Stats.xls-Datei nicht enthalten.\n');
                 AnalyseStatsout = [];
                 return;
             end
             
             % Funktion Beenden wenn nicht alle Daten eingelesen wurden konnten
             if isempty(DataBaseline)
                AnalyseStatsout = [];
                return;
             end
             
             % Daten auswerten
             rel_delta_mean   = 100*(Data.(sprintf('sheet_%d', 1)).Mean(ExcelZeile) - DataBaseline.(sprintf('sheet_%d', 1)).Mean(ExcelZeile) ) ./ DataBaseline.(sprintf('sheet_%d', 1)).Mean(ExcelZeile);
             rel_delta_StdDev = 100*(Data.(sprintf('sheet_%d', 1)).StdDev(ExcelZeile) - DataBaseline.(sprintf('sheet_%d', 1)).StdDev(ExcelZeile) ) ./ DataBaseline.(sprintf('sheet_%d', 1)).StdDev(ExcelZeile);
             
             % Ergebnisse Zusammenfassen
             results.RelDeltaMean   = rel_delta_mean;
             results.RelDeltaStdDev = rel_delta_StdDev;
             results.sheets         = sheets(1:end);
             
             % Ausgabe der Ergebnisse
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Baselinecase-Ordner: %s \n', folderNamesBaselineCase(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);

            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            fprintf('Relative Änderungen des Mittelwerts und der Standardabweichung im Vergleich zum Referenzfall %s:\n', BaselineCase);
            fprintf('------------------------------------');
            
            fprintf('| %s ', sheets);        
            fprintf('|\n');
            fprintf('Änderungen der Mittelwerte          |');        
            fprintf('             %.2f %%            | ',rel_delta_mean);       
            fprintf('\nÄnderungen der Standardabweichungen |');            
            fprintf('             %.2f %%            | ',rel_delta_StdDev);
            fprintf('\n'); 
                          
     end
     
     % Erstellen des Outputs
     AnalyseStatsout.(sprintf('%s',folderNames(z).name)) = results;
     
     % Speicher der Ergebnisse als .mat-Datei
     StatsAnalyseResults.(sprintf('%s',folderNames(z).name)) = results; 
     save([SimRunFolderPath filesep folderNames(z).name filesep 'StatsAnalyseResults.mat'], 'StatsAnalyseResults');
     clear StatsAnalyseResults
                  
 end
 
end

