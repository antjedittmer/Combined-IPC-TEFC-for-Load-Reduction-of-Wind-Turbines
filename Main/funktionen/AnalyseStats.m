function [AnalyseStatsout] = AnalyseStats(SimRunFolderPath, BaselineCase)
%ANALYSESTATS Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('Statistik-Analyse wird durchgeführt. \n');
 
 numVars = 8;
 varNames = {'Parameter','Units','Minimum','Mean','Maximum','StdDev','Skewness', 'Range'};
 varTypes = {'char','char','double', 'double', 'double' ,'double' ,'double', 'double'} ;
 
 
 opts = spreadsheetImportOptions('NumVariables',numVars, 'VariableNames',varNames, 'VariableTypes',varTypes);
 opts.DataRange = 'A7:H151';

if isfile(fullfile(SimRunFolderPath,'Log.text')) == 1
    LoopStart = 4;
else
    LoopStart = 3;
end
 
 for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
    AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
    ExcelFileName = 'Analyse_Stats.xls';
    filename = [AnlyseFolderPath filesep ExcelFileName];
    sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
    BaselineCaseStatus = "Fslse";

    for i = 2 : length(sheets)  
        
        % Pruefen, ob BaselineCase in sheets enthalten ist
        if sheets(i) == BaselineCase && BaselineCaseStatus == "Fslse"
            BaselineCaseStatus = "True";
            BaselineIndex = i-1;
            fprintf('Der Referenzfall wurde gefunden.\n');
        end
        
        % Einlesen der Daten 
        opts.Sheet = sheets(i);
        Stats = readtable(filename,opts);
        Data.(sprintf('sheet_%d', i-1)) = Stats;       
    end
    
    if BaselineCaseStatus == "Fslse"
        fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
        AnalyseStatsout = [];
        return;
    end
    
    % Daten Auswertung
    if (length(sheets) >= 3) && (BaselineCaseStatus == "True")        
        for i = 2 : length(sheets)
            rel_delta_mean(i-1)   = 100*(Data.(sprintf('sheet_%d', i-1)).Mean(30) - Data.(sprintf('sheet_%d', BaselineIndex)).Mean(30) ) ./ Data.(sprintf('sheet_%d', BaselineIndex)).Mean(30);
            rel_delta_StdDev(i-1) = 100*(Data.(sprintf('sheet_%d', i-1)).StdDev(30) - Data.(sprintf('sheet_%d', BaselineIndex)).StdDev(30) ) ./ Data.(sprintf('sheet_%d', BaselineIndex)).StdDev(30);
        end 
        
        % Ergebnisse Zusammenfassen
        results.RelDeltaMean   = rel_delta_mean;
        results.RelDeltaStdDev = rel_delta_StdDev;

        % Ausgabe der Ergebnisse
        fprintf('\n---------------------------------------------------------\n');
        fprintf('Simulationsordner: %s \n', folderNames(z).folder);
        fprintf('Windtestfall: %s \n', folderNames(z).name);
        
        fprintf('Der Referenzfall ist: %s\n', BaselineCase);
        fprintf('Relative Änderungen des Mittelwerts und der Standardabweichung im Vergleich zum Referenzfall %s:\n', BaselineCase);
        fprintf('------------------------------------');
        for j = 2 : length(sheets)
           fprintf('| %s ', sheets(j));
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
               
    end
    % Erstellen des Outputs
    results.sheets = sheets(2:end);
    AnalyseStatsout.(sprintf('%s',folderNames(z).name)) = results; 
    
    
    
 end
end

