function [pks, intPSD, BaselineIndex, sheets] = readDataPSD(SimRunFolderPath, idx, BaselineCase, Optimization, readBaselineData)
%READDATAPSD Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);
 z = idx;
     switch Optimization
         case 'false'
             AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
             ExcelFileName = 'Analyse_PSDs.xls';
             sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
             BaselineCaseStatus = "Fslse";

             % Pruefen, ob BaselineCase in sheets enthalten ist
             for i = 2 : length(sheets)
                if sheets(i) == BaselineCase && BaselineCaseStatus == "Fslse"
                    BaselineCaseStatus = "True";
                    BaselineIndex = i-1;
                    fprintf('Der Referenzfall wurde gefunden.\n');
                end
             end

             if BaselineCaseStatus == "Fslse"
                fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                BaselineIndex = [];
                pks = [];
                intPSD = [];
                return;
             end
          
             % Einlesen der Daten 
             if length(sheets) == 1
                 pks = [];
                 intPSD = [];
                 BaselineIndex = [];
                 fprintf('Es wurde keine Statistikanalyse durchgeführt, da in den Eingelesenen Daten nur ein Testfall vorhanden ist.\n');
                 return;
             else
                 loopStart = 2;
                 delta_idx = 1;
             end
                         
             % Daten aus PSD auslesen
             for i = loopStart : length(sheets)
                [pks(:,i-delta_idx) , ~, intPSD(i-delta_idx)] = ExtractPSD(AnlyseFolderPath, ExcelFileName, sheets(i));  
             end
             
                        
         case 'true'
             switch readBaselineData
                 case 'true'  
                     AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
                     ExcelFileName = 'Analyse_PSDs.xls';
                     sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
                     BaselineCaseStatus = "Fslse";

                     % Pruefen, ob BaselineCase in sheets enthalten ist
                     for i = 1 : length(sheets)
                        if sheets(i) == BaselineCase && BaselineCaseStatus == "Fslse"
                            BaselineCaseStatus = "True";
                            BaselineIndex = [];
                            fprintf('Der Referenzfall wurde gefunden.\n');
                        end
                     end

                     if BaselineCaseStatus == "Fslse"
                        fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                        BaselineIndex = [];
                        pks = [];
                        intPSD = [];
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

                     % Daten aus PSD auslesen
                     for i = loopStart : length(sheets)
                        [pks(:,i-delta_idx) , ~, intPSD(i-delta_idx)] = ExtractPSD(AnlyseFolderPath, ExcelFileName, sheets(i));  
                     end
                     
                                   
                 case 'false'
                     AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
                     ExcelFileName = 'Analyse_PSDs.xls';
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

                     % Daten aus PSD auslesen
                     for i = loopStart : length(sheets)
                        [pks(:,i-delta_idx) , ~, intPSD(i-delta_idx)] = ExtractPSD(AnlyseFolderPath, ExcelFileName, sheets(i));  
                     end                    
                     
             end
             
     end
end

