function [PowerReferenceAnalyseOut] = PowerReferenceAnalyse(SimRunFolderPath, BaselineCase, BaselineCaseFolderPath, DoOptimization, UserInputs)
%POWERREFERENCEANALYSE Summary of this function goes here
%   Detailed explanation goes here

folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('Power-Analyse wird durchgeführt. \n');
 
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
         PowerReferenceAnalyseOut = [];
         return;
     end
     
     for x = LoopStart : length(folderNames)
         if folderNames(x).name ~= folderNamesBaselineCase(x).name
             fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
             PowerReferenceAnalyseOut = [];
             return;
         end
     end
 end
 

  for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
      switch DoOptimization
         case "false"
             
            % Augabe der Ergebnisse einleiten
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            
             readBaselineData = 'false';
             % Einlesen der Power-reference-Daten
             [PowerElec]  = LoadPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerElec", UserInputs.StartDatalogging);
             [PowerRef]   = LoadPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerRef", UserInputs.StartDatalogging);
             PowerElecMat =  table2array(PowerElec);
             PowerRefMat  = table2array(PowerRef);
             
             PowerElecMatn = PowerElecMat;
             PowerRefMatn  = PowerRefMat;
             
             % Mittelwerte der Leistungen
             PowerElecMean = mean(PowerElecMatn,1);
             PowerRefMean  = mean(PowerRefMatn,1);
             
             % Standardabweichungen der Leistungen
             PowerElecStd = std(PowerElecMatn);
             PowerRefStd  = std(PowerRefMatn);
             
             % Relative Änderungen der Standardabweichungen
             for r = 1 : length(PowerElecStd)
                PowerElecStdRelChange(r) = (PowerElecStd(r) - PowerElecStd(1,1)) .*100 ./ PowerElecStd(1,1);
                PowerRefStdRelChange(r) = (PowerRefStd(r) - PowerRefStd(1,1)) .*100 ./ PowerRefStd(1,1);
             end
             
             % Relative Änderung der mittleren el. Leistung
             for r = 1 : length(PowerElecMean)
                PowerElecMeanRelChange(r) = (PowerElecMean(r) - PowerElecMean(1,1)) .*100 ./ PowerElecMean(1,1);                
             end
             
             % Relative Abweichung der el. Leistung von der Ref. Leistung
             PowerC1 = abs( (PowerElecMean - PowerRefMean) .*100 ./ PowerRefMean );
             
             % Relative Änderung der Abweichungen der el. Leistung von der
             % Ref. Leistung
             CaseNames = PowerElec.Properties.VariableNames;
             for j = 1 : length(PowerC1)
                PowerC2(j) = (PowerC1(1,j) - PowerC1(1,1)) .*100 ./ PowerC1(1,1) ;
                %Case = char(CaseNames(j));
                %Case = string(Case(1:end-4));
                %results.(sprintf('%s',Case)).PowerCriteria = PowerC2(j);
             end
             
             % Tabelle erstellen
             sz = [9 (length(CaseNames)+1)];
             varTypes = {'categorical'};
             varNames = {'Units'};
             for i = 1 : length(CaseNames)
                varTypes(i+1) = {'double'};
                CaseName = char(CaseNames(i));
                varNames(i+1) = {CaseName(24:end-4)};
             end
             
             TPowerAnalyse = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',...
             {'Mittelwerte der elektrischen Leistung';...
             'Änderung der mittleren el. Leistung';...
             'Mittelwerte der Referenzleistung';...
             'Relative Leistungsfolgegenauigkeit';...
             'Änderungen der Leistungsfolgegenauigkeit';...
             'Standardabweichung der el. Leistung';...
             'Standardabweichung der ref. Leistung';...
             'Änderung der Standardabweichung der el. Leistung';...
             'Änderung der Standardabweichung der ref. Leistung'});
        
         
             % Tabelle befüllen
             TPowerAnalyse(1,1) = {'[kW]'};
             TPowerAnalyse(2,1) = {'[%]'};
             TPowerAnalyse(3,1) = {'[kW]'};
             TPowerAnalyse(4,1) = {'[%]'};
             TPowerAnalyse(5,1) = {'[%]'};
             TPowerAnalyse(6,1) = {'[kW]'};
             TPowerAnalyse(7,1) = {'[kW]'};
             TPowerAnalyse(8,1) = {'[%]'};
             TPowerAnalyse(9,1) = {'[%]'};          
             
             TPowerAnalyse(1,2:end) = array2table(PowerElecMean);
             TPowerAnalyse(2,2:end) = array2table(PowerElecMeanRelChange);
             TPowerAnalyse(3,2:end) = array2table(PowerRefMean);
             TPowerAnalyse(4,2:end) = array2table(PowerC1);
             TPowerAnalyse(5,2:end) = array2table(PowerC2);
             TPowerAnalyse(6,2:end) = array2table(PowerElecStd);
             TPowerAnalyse(7,2:end) = array2table(PowerRefStd);
             TPowerAnalyse(8,2:end) = array2table(PowerElecStdRelChange);
             TPowerAnalyse(9,2:end) = array2table(PowerRefStdRelChange);
             
             % Ausgabe der Ergebnisse
             disp(TPowerAnalyse)
                                
          case "true"
            % Augabe der Ergebnisse einleiten
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Baselinecase-Ordner: %s \n', folderNamesBaselineCase(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
              
             readBaselineData = 'false';
             % Einlesen der Power-reference-Daten
             [PowerElec]  = LoadPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerElec", UserInputs.StartDatalogging);
             [PowerRef]   = LoadPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerRef", UserInputs.StartDatalogging);
             PowerElecMat =  table2array(PowerElec);
             PowerRefMat  = table2array(PowerRef);
             
             readBaselineData = 'true';
             % Einlesen der Power-reference-Daten
             [PowerElecBaseline]  = LoadPowerData(BaselineCaseFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerElec", UserInputs.StartDatalogging);
             [PowerRefBaseline]   = LoadPowerData(BaselineCaseFolderPath, z, BaselineCase, DoOptimization, readBaselineData, "PowerRef", UserInputs.StartDatalogging);
             PowerElecMatBaseline =  table2array(PowerElecBaseline);
             PowerRefMatBaseline  = table2array(PowerRefBaseline);             
             
             
             PowerElecMatn = PowerElecMat;
             PowerRefMatn = PowerRefMat;
             
             PowerElecMatnBaseline = PowerElecMatBaseline;
             PowerRefMatnBaseline = PowerRefMatBaseline;
             
             % Mittelwerte der Leistungen
             PowerElecMean = mean(PowerElecMatn,1);
             PowerRefMean = mean(PowerRefMatn,1);
             
             PowerElecMeanBaseline = mean(PowerElecMatnBaseline,1);
             PowerRefMeanBaseline = mean(PowerRefMatnBaseline,1);
             
             PowerElecMean = [PowerElecMeanBaseline  PowerElecMean];
             PowerRefMean = [PowerRefMeanBaseline  PowerRefMean];
             
             % Standardabweichungen der Leistungen
             PowerElecStd = std(PowerElecMatn);
             PowerRefStd  = std(PowerRefMatn);  
             
             PowerElecStdBaseline = std(PowerElecMatnBaseline);
             PowerRefStdBaseline = std(PowerRefMatnBaseline);
             
             PowerElecStd = [PowerElecStdBaseline  PowerElecStd];
             PowerRefStd  = [PowerRefStdBaseline  PowerRefStd]; 
             
             % Relative Änderungen der Standardabweichungen
             for r = 1 : length(PowerElecStd)
                PowerElecStdRelChange(r) = (PowerElecStd(r) - PowerElecStd(1,1)) .*100 ./ PowerElecStd(1,1);
                PowerRefStdRelChange(r) = (PowerRefStd(r) - PowerRefStd(1,1)) .*100 ./ PowerRefStd(1,1);
             end 
             
             % Relative Änderung der mittleren el. Leistung
             for r = 1 : length(PowerElecMean)
                PowerElecMeanRelChange(r) = (PowerElecMean(r) - PowerElecMean(1,1)) .*100 ./ PowerElecMean(1,1);                
             end             
             
                 
             % Relative Abweichung der el. Leistung von der Ref. Leistung
             PowerC1 = abs( (PowerElecMean - PowerRefMean) .*100 ./ PowerRefMean );
             %PowerC1Baseline = abs( (PowerElecMeanBaseline - PowerRefMeanBaseline) .*100 ./ PowerRefMeanBaseline );
                          
             % Relative Änderung der Abweichungen der el. Leistung von der
             % Ref. Leistung             
            PowerC2 = (PowerC1(1,2) - PowerC1(1,1)) .*100 ./ PowerC1(1,1) ;
            
            CaseNames = PowerElec.Properties.VariableNames;    
            %Case = char(CaseNames);
            %Case = string(Case(1:end-4));
            %results.(sprintf('%s',Case)).PowerCriteria = PowerC2;
            
             % Tabelle erstellen
             sz = [9 (length(CaseNames)+1)];
             varTypes = {'categorical'};
             varNames = {'Units'};
             for i = 1 : length(CaseNames)
                varTypes(i+1) = {'double'};
                CaseName = char(CaseNames(i));
                varNames(i+1) = {CaseName(24:end-4)};
             end
             
             TPowerAnalyse = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',...
             {'Mittelwerte der elektrischen Leistung';...
             'Änderung der mittleren el. Leistung';...
             'Mittelwerte der Referenzleistung';...
             'Relative Leistungsfolgegenauigkeit';...
             'Änderungen der Leistungsfolgegenauigkeit';...
             'Standardabweichung der el. Leistung';...
             'Standardabweichung der ref. Leistung';...
             'Änderung der Standardabweichung der el. Leistung';...
             'Änderung der Standardabweichung der ref. Leistung'});
        
         
             % Tabelle befüllen
             TPowerAnalyse(1,1) = {'[kW]'};
             TPowerAnalyse(2,1) = {'[%]'};
             TPowerAnalyse(3,1) = {'[kW]'};
             TPowerAnalyse(4,1) = {'[%]'};
             TPowerAnalyse(5,1) = {'[%]'};
             TPowerAnalyse(6,1) = {'[kW]'};
             TPowerAnalyse(7,1) = {'[kW]'};
             TPowerAnalyse(8,1) = {'[%]'};
             TPowerAnalyse(9,1) = {'[%]'};          
             
             TPowerAnalyse(1,2:end) = array2table(PowerElecMean(2));
             TPowerAnalyse(2,2:end) = array2table(PowerElecMeanRelChange(2));
             TPowerAnalyse(3,2:end) = array2table(PowerRefMean(2));
             TPowerAnalyse(4,2:end) = array2table(PowerC1(2));
             TPowerAnalyse(5,2:end) = array2table(PowerC2);
             TPowerAnalyse(6,2:end) = array2table(PowerElecStd(2));
             TPowerAnalyse(7,2:end) = array2table(PowerRefStd(2));
             TPowerAnalyse(8,2:end) = array2table(PowerElecStdRelChange(2));
             TPowerAnalyse(9,2:end) = array2table(PowerRefStdRelChange(2));
             
             % Ausgabe der Ergebnisse
             disp(TPowerAnalyse)   
             
             clear PowerElecMean PowerRefMean PowerElecStd PowerRefStd
                                          
      end
       

    % Erstellen des Outputs
     PowerReferenceAnalyseOut.(sprintf('%s',folderNames(z).name)) = TPowerAnalyse;
     
     % Speicher der Ergebnisse als .mat-Datei 
     save([SimRunFolderPath filesep folderNames(z).name filesep 'PowerReferenceAnalyseOut.mat'], 'PowerReferenceAnalyseOut');
     
    
    
  end

end

