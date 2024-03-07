function [Data,BaselineIndex,sheets] = readDataStats(SimRunFolderPath, idx, BaselineCase, Optimization, readBaselineData)
%READDATASTATS Summary of this function goes here
%   Detailed explanation goes here

% Optionen zum Einlesen der Daten einstellen
 numVars = 8;
 varNames = {'Parameter','Units','Minimum','Mean','Maximum','StdDev','Skewness', 'Range'};
 varTypes = {'char','char','double', 'double', 'double' ,'double' ,'double', 'double'};
 opts = spreadsheetImportOptions('NumVariables',numVars, 'VariableNames',varNames, 'VariableTypes',varTypes);
 opts.DataRange = 'A7:H151';                                               % Muss evtl angepasst werden, wenn die OutList verändert wird

 folderNames = dir(SimRunFolderPath);
 z = idx;
    switch Optimization
            case 'false'
                AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
                ExcelFileName = 'Analyse_Stats.xls';
                filename = [AnlyseFolderPath filesep ExcelFileName];
                sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
                BaselineCaseStatus = "Fslse";

                % Pruefen, ob BaselineCase in sheets enthalten ist
                for ii = 2 : length(sheets)  
                    if sheets(ii) == BaselineCase && BaselineCaseStatus == "Fslse"
                        BaselineCaseStatus = "True";
                        BaselineIndex = ii-1;
                        fprintf('Der Referenzfall wurde gefunden.\n');
                    end      
                end

                if BaselineCaseStatus == "Fslse"
                    fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                    Data = [];
                    BaselineIndex = [];
                    return;
                end  

                % Einlesen der Daten 
                if length(sheets) == 1
                    Data = [];
                    BaselineIndex = [];
                    fprintf('Es wurde keine Statistikanalyse durchgeführt, da in den Eingelesenen Daten nur ein Testfall vorhanden ist.\n');
                    return;
                else
                    loopStart = 2;
                    delta_idx = 1;
                end
                
                for iii = loopStart : length(sheets) 
                    opts.Sheet = sheets(iii);
                    Stats = readtable(filename,opts);
                    Data.(sprintf('sheet_%d', iii-delta_idx)) = Stats;    
                end
                
            case 'true'
                switch readBaselineData
                    case 'true'               
                        AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
                        ExcelFileName = 'Analyse_Stats.xls';
                        filename = [AnlyseFolderPath filesep ExcelFileName];
                        sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
                        BaselineCaseStatus = "Fslse";

                        % Pruefen, ob BaselineCase in sheets enthalten ist
                        for ii = 1 : length(sheets)  
                            if sheets(ii) == BaselineCase && BaselineCaseStatus == "Fslse"
                                BaselineCaseStatus = "True";
                                BaselineIndex = [];
                                fprintf('Der Referenzfall wurde gefunden.\n');
                            end      
                        end

                        if BaselineCaseStatus == "Fslse"
                            fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                            Data = [];
                            BaselineIndex = [];
                            return;
                        end  

                        % Einlesen der Daten 
                        if length(sheets) == 1
                            loopStart = 1;
                            delta_idx = 0;
                        else
                            loopStart = 2;
                            delta_idx = 1;
                        end
                        
                        for iii = loopStart : length(sheets) 
                            opts.Sheet = sheets(iii);
                            Stats = readtable(filename,opts);
                            Data.(sprintf('sheet_%d', iii-delta_idx)) = Stats;    
                        end
                    case 'false'
                        AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
                        ExcelFileName = 'Analyse_Stats.xls';
                        filename = [AnlyseFolderPath filesep ExcelFileName];
                        sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
                        BaselineIndex = [];
                        % Einlesen der Daten 
                        if length(sheets) == 1
                            loopStart = 1;
                            delta_idx = 0;
                        else
                            loopStart = 2;
                            delta_idx = 1;
                        end                        
                        
                        for iii = loopStart : length(sheets) 
                            opts.Sheet = sheets(iii);
                            Stats = readtable(filename,opts);
                            Data.(sprintf('sheet_%d', iii-delta_idx)) = Stats;    
                        end
                end
                       
    end
        
end

