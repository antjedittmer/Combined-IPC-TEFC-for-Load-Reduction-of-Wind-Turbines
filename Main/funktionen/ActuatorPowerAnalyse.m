function [ActuatorPowerAnalyseOut] = ActuatorPowerAnalyse(SimRunFolderPath, BaselineCase, BaselineCaseFolderPath, DoOptimization, UserInputs)
%ACTUATORPOWERANALYSE Summary of this function goes here
%   Detailed explanation goes here

folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('Aktuator-Power-Analyse wird durchgeführt. \n');
 
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
         ActuatorPowerAnalyseOut = [];
         return;
     end
     
     for x = LoopStart : length(folderNames)
         if folderNames(x).name ~= folderNamesBaselineCase(x).name
             fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
             ActuatorPowerAnalyseOut = [];
             return;
         end
     end
 end
 

  for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
      switch DoOptimization
         case "false"
             readBaselineData = 'false';
             % Einlesen der Power-reference-Daten             
             PowerAct = LoadActuatorPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, UserInputs.StartDatalogging);     
             PowerActMat =  table2array(PowerAct);
             
             DataStartIdx = 1;
%              for i = 1 : length(PowerActMat)
%                  if PowerActMat(i,1) ~= 0 && DataStartIdx == 0
%                      DataStartIdx = i;
%                  end
%              end             
             PowerActMatn = PowerActMat(DataStartIdx:end,:);
             
             PowerActMean = mean(PowerActMatn,1);
             
             [~,n] = size(PowerActMean);
             u = 1;
             for j = 1 : (n/3)
                PowerActSum(:,j) = PowerActMean(:,u) + PowerActMean(:,u+1) + PowerActMean(:,u+2);
                u = u + 3;
             end
             PowerActSum = PowerActSum./3;
             
             for r = 1 : length(PowerActSum)
                PowerActRelChange(1,r) = ( PowerActSum(r) - PowerActSum(1) )*100 / PowerActSum(1);
             end
             
             
             CaseNamesAll = PowerAct.Properties.VariableNames;
             v = 1;
             for k = 1 : length(CaseNamesAll)/3
                CaseNames(k) = CaseNamesAll(v);
                v = v + 3;
             end
             
            
             % Tabelle erstellen
             sz = [2 (length(CaseNames)+1)];
             varTypes = {'categorical'};
             varNames = {'Units'};
             for i = 1 : length(CaseNames)
                varTypes(i+1) = {'double'};
                CaseName = char(CaseNames(i));
                varNames(i+1) = {CaseName(22:end-6)};
             end
             
             TActuatorPowerAnalyse = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',...
             {'Mittlere Aktuatorleistung';...
             'Änderungen der mittleren Aktuatorleistung'});
        
         
             % Tabelle befüllen
             TActuatorPowerAnalyse(1,1) = {'[kW]'};
             TActuatorPowerAnalyse(2,1) = {'[%]'};          
             
             TActuatorPowerAnalyse(1,2:end) = array2table(PowerActSum);
             TActuatorPowerAnalyse(2,2:end) = array2table(PowerActRelChange);
             
             % Ausgabe der Ergebnisse
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
             disp(TActuatorPowerAnalyse) 
             
             clear CaseNames PowerActSum
                
                       
          case "true"
              
             readBaselineData = 'false';
             % Einlesen der Power-reference-Daten             
             PowerAct = LoadActuatorPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData, UserInputs.StartDatalogging);     
             PowerActMat =  table2array(PowerAct);
              
             readBaselineData = 'true';
             % Einlesen der Power-reference-Daten             
             PowerActBaseline = LoadActuatorPowerData(BaselineCaseFolderPath, z, BaselineCase, DoOptimization, readBaselineData, UserInputs.StartDatalogging);     
             PowerActMatBaseline =  table2array(PowerActBaseline);
              
             DataStartIdx = 1;
%              for i = 1 : length(PowerActMatBaseline)
%                  if PowerActMat(i,1) ~= 0 && DataStartIdx == 0
%                      DataStartIdx = i;
%                  end
%              end             
             PowerActMatn         = PowerActMat(DataStartIdx:end,:);
             PowerActMatnBaseline = PowerActMatBaseline(DataStartIdx:end,:);
             
             PowerActMean         = mean(PowerActMatn,1); 
             PowerActMeanBaseline = mean(PowerActMatnBaseline,1); 
             
             [~,n] = size(PowerActMean);
             u = 1;
             for j = 1 : (n/3)
                PowerActSum(:,j) = PowerActMean(:,u) + PowerActMean(:,u+1) + PowerActMean(:,u+2);
                u = u + 3;
             end
             PowerActSumBaseline(:,1) = PowerActMeanBaseline(:,1) + PowerActMeanBaseline(:,2) + PowerActMeanBaseline(:,3);
             
             PowerActSum         = PowerActSum./3;
             PowerActSumBaseline = PowerActSumBaseline./3;
             
             
             PowerActSum = [PowerActSumBaseline PowerActSum];
             
             for r = 1 : length(PowerActSum)
                PowerActRelChange(1,r) = ( PowerActSum(r) - PowerActSum(1) )*100 / PowerActSum(1);
             end
                                             
             CaseNamesAll = PowerAct.Properties.VariableNames;
             v = 1;
             for k = 1 : length(CaseNamesAll)/3
                CaseNames(k) = CaseNamesAll(v);
                v = v + 3;
             end
             CaseNameBaseline = PowerActBaseline.Properties.VariableNames;
             CaseNames        = [CaseNameBaseline(1) CaseNames];
                          
             % Tabelle erstellen
             sz = [2 (length(CaseNames)+1)];
             varTypes = {'categorical'};
             varNames = {'Units'};
             for i = 1 : length(CaseNames)
                varTypes(i+1) = {'double'};
                CaseName = char(CaseNames(i));
                varNames(i+1) = {CaseName(22:end-6)};
             end
             
             TActuatorPowerAnalyse = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames,'RowNames',...
             {'Mittlere Aktuatorleistung';...
             'Änderungen der mittleren Aktuatorleistung'});
        
         
             % Tabelle befüllen
             TActuatorPowerAnalyse(1,1) = {'[kW]'};
             TActuatorPowerAnalyse(2,1) = {'[%]'};          
             
             TActuatorPowerAnalyse(1,2:end) = array2table(PowerActSum);
             TActuatorPowerAnalyse(2,2:end) = array2table(PowerActRelChange);
             
             % Ausgabe der Ergebnisse
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Baselinecase-Ordner: %s \n', folderNamesBaselineCase(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
             disp(TActuatorPowerAnalyse) 
             
             clear CaseNames PowerActSum
             
                                                                    
      end
       
    % Erstellen des Outputs
     ActuatorPowerAnalyseOut.(sprintf('%s',folderNames(z).name)) = TActuatorPowerAnalyse;
     
     % Speicher der Ergebnisse als .mat-Datei 
     save([SimRunFolderPath filesep folderNames(z).name filesep 'ActuatorPowerAnalyseOut.mat'], 'ActuatorPowerAnalyseOut');
     
       
  end

end

