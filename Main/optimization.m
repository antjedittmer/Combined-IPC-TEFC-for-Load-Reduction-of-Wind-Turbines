function [] = optimization(UserInputs)
%UNTITLED Summary of this function goes here
%   Funktion zum ausführen von Optimierungen

%% Baselinecase Simulieren und Analysieren
                
% Prüfen, dass nur ein Windfile verwendet wird
%UserInputs.WindDataFiles

% Simulationen und MCrunch
UserInputs.ActionCommands.MCrunch             = 'Yes';
UserInputs.ActionCommands.Simulations         = 'Yes';

% Further Post-Processing
UserInputs.Optimization.Do                               = "false";
UserInputs.FurtherPostProcessing.PSDanalyse.Do           = 'No';
UserInputs.FurtherPostProcessing.StatsAnalyse.Do         = 'No';
UserInputs.FurtherPostProcessing.DELanalyse.Do           = 'No';
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do = 'No';
UserInputs.FurtherPostProcessing.PowerAnalyse.Do         = 'No';
UserInputs.CostFunktion.Do                               = 'No';

% Basisregler einschalten
UserInputs.CPC_Controller.Switch   = 'on';
UserInputs.GenTq_Controller.Switch = 'on';

% IPC- und TEF-Regler abschalten
UserInputs.IPC_Controller.Switch = 'off';
UserInputs.TEF_Controller.Switch = 'off';

% Optimierung
UserInputs.Optimization.Do = "false";
UserInputs.Optimization.BaselineCaseFolderPath = [];

% Baselinecase erzeugen
[~, SimRunFolderPath] = main(UserInputs);


%% Opiemierung Starten
% Further Post-Processing
UserInputs.Optimization.Do                               = "true";
UserInputs.FurtherPostProcessing.PSDanalyse.Do           = 'Yes';
UserInputs.FurtherPostProcessing.StatsAnalyse.Do         = 'Yes';
UserInputs.FurtherPostProcessing.DELanalyse.Do           = 'Yes';
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do = 'Yes';
UserInputs.FurtherPostProcessing.PowerAnalyse.Do         = 'Yes';
UserInputs.CostFunktion.Do                               = 'Yes';

BaselineCase = "5MW_Land.SFunc_TEF_off_IPC_off";
UserInputs.FurtherPostProcessing.PSDanalyse.BaselineCase   = BaselineCase;
UserInputs.FurtherPostProcessing.StatsAnalyse.BaselineCase = BaselineCase;
UserInputs.FurtherPostProcessing.DELanalyse.BaselineCase   = BaselineCase;

% Regler entsprechend dem gewählten Testcase einschalten        
switch UserInputs.Optimization.Testcase
    case "5MW_Land.SFunc_TEF_off_IPC_off"
        fprintf('Der gewählte Testcase entspricht dem Baselinecase. Um eine Optimierung durchzuführen muss der Testcase ein anderer als der Baselinecase sein.\n');
        return;
    case "5MW_Land.SFunc_TEF_off_IPC_on"                 
        UserInputs.IPC_Controller.Switch = 'on';
        UserInputs.TEF_Controller.Switch = 'off';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    case "5MW_Land.SFunc_TEF_on_IPC_off"                 
        UserInputs.IPC_Controller.Switch = 'off';
        UserInputs.TEF_Controller.Switch = 'on';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    case "5MW_Land.SFunc_TEF_on_IPC_on"                 
        UserInputs.IPC_Controller.Switch = 'on';
        UserInputs.TEF_Controller.Switch = 'on';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    otherwise
        fprintf('Die Eingabe für den Testcase ist ungültig. Wählen Sie eine der folgenden Möglichkeiten:\n');
        fprintf(' "5MW_Land.SFunc_TEF_off_IPC_on" \n');
        fprintf(' "5MW_Land.SFunc_TEF_on_IPC_off" \n');
        fprintf(' "5MW_Land.SFunc_TEF_on_IPC_on" \n');
        return;
end

% Den Pfad zu den Simulationsergebnisen des Baselinecase angeben
UserInputs.Optimization.BaselineCaseFolderPath = SimRunFolderPath;

% Ordner zum Speichern der Optimierungsergebnisse erstellen
t                = datetime;
t.Format         = 'dd-MMM-yy_HH-mm';
OptimizationResultsFolderName = append('Optimierung_Ergebnisse_', char(t));
mkdir('Post_processing',OptimizationResultsFolderName); 
OptimizationResultsFolderPath = fullfile(pwd,'Post_processing',OptimizationResultsFolderName);

% Startwerte für Reglergains definieren
switch UserInputs.IPC_Controller.Typ
    case "P"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x0 = [  UserInputs.IPC_Controller.K_P,...     
                        UserInputs.TEF_Controller.K_P   ];                
            case "I"
                x0 = [  UserInputs.IPC_Controller.K_P,...     
                        UserInputs.TEF_Controller.K_I   ];                  
            case "PI"
                x0 = [  UserInputs.IPC_Controller.K_P,...      
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I   ];                
            case "PID"
                x0 = [  UserInputs.IPC_Controller.K_P,...      
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I,...    
                        UserInputs.TEF_Controller.K_D   ];                
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end
    case "I"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x0 = [  UserInputs.IPC_Controller.K_I,...     
                        UserInputs.TEF_Controller.K_P   ];                
            case "I"
                x0 = [  UserInputs.IPC_Controller.K_I,...     
                        UserInputs.TEF_Controller.K_I   ];                  
            case "PI"
                x0 = [  UserInputs.IPC_Controller.K_I,...      
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I   ];                
            case "PID"
                x0 = [  UserInputs.IPC_Controller.K_I,...      
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I,...    
                        UserInputs.TEF_Controller.K_D   ];                
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end        
    case "PI"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...     
                        UserInputs.TEF_Controller.K_P   ];                
            case "I"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...      
                        UserInputs.TEF_Controller.K_I   ];                  
            case "PI"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...       
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I   ];                
            case "PID"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...       
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I,...    
                        UserInputs.TEF_Controller.K_D   ];                
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end                
    case "PID"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...   
                        UserInputs.IPC_Controller.K_D,...        
                        UserInputs.TEF_Controller.K_P   ];                
            case "I"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...   
                        UserInputs.IPC_Controller.K_D,...         
                        UserInputs.TEF_Controller.K_I   ];                  
            case "PI"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...   
                        UserInputs.IPC_Controller.K_D,...          
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I   ];                
            case "PID"
                x0 = [  UserInputs.IPC_Controller.K_P,...   
                        UserInputs.IPC_Controller.K_I,...   
                        UserInputs.IPC_Controller.K_D,...   
                        UserInputs.TEF_Controller.K_P,...    
                        UserInputs.TEF_Controller.K_I,...    
                        UserInputs.TEF_Controller.K_D   ];                
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end              
    otherwise
        fprintf('\nDie Eingabe für den Reglertyp der IPC ist ungültig. (P, I, PI, oder PID)\n');
        return;
end

% Globale Variable (Tabelle) zum aufzeichenen der
% Function-Evaluation-History initialisieren

% global FunEvalHistory
% sz = [0 11];
% varNames = {'Date',...
%             'Time',...
%             'IPC_KP',...
%             'IPC_KI',...
%             'IPC_KD',...
%             'TEF_KP',...
%             'TEF_KI',...
%             'TEF_KD',...
%             'Iteration',...
%             'Func-count',...
%             'funValue'};
% varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double'};
% FunEvalHistory = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);


% Optimierungsfunktion in Abhängigkeit von x aufstellen
fun = @(x)main(UserInputs,x);

% Optimierung entsprechend der ausgewählten Optimierungsfunktion Starten
switch UserInputs.Optimization.Function
    case "fminsearch"
        [x] = fminsearchStart(UserInputs,fun,x0,OptimizationResultsFolderPath);
               
    case "fmincon"
        fprintf('\n fmincon wird ausgeführt.\n');
        [x] = fminconStart(UserInputs,fun,x0,OptimizationResultsFolderPath);
               
    otherwise
        fprintf('\nDie Eingabe zur Auswahl der Optimierungsfunktion ist ungültig.\n');
        return;
end
        
% Ergebnisse der Optimierung Speichern
SaveOptimizationResults(UserInputs,OptimizationResultsFolderPath,x);


end

