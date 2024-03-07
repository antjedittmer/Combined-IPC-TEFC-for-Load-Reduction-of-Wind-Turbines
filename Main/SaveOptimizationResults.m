function [] = SaveOptimizationResults(UserInputs,OptimizationResultsFolderPath,x)
%SAVEOPTIMIZATIONRESULTS Summary of this function goes here
%   Funktion zum Speichern der Optimierungsergebnisse

global history

% Text-Datei öffnen
OptimizationRsultsFileName = 'Optimization_Results_&_History.txt';
OptimizationRsultsFilePath = fullfile(OptimizationResultsFolderPath,OptimizationRsultsFileName); 
fileID = fopen(OptimizationRsultsFilePath,'a');

% Optimierungshistory in Text Datei schreiben
writetable(history,OptimizationRsultsFilePath,'Delimiter',' '); 
writetable(history,fullfile(OptimizationResultsFolderPath,'Optimization_History.xls')); 

% Unterscheidung nach Reglertyp
switch UserInputs.IPC_Controller.Typ
    case "P"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x_res(1) = x(1);
                x_res(2) = 0;
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = 0;
                x_res(6) = 0;                
            case "I"
                x_res(1) = x(1);
                x_res(2) = 0;
                x_res(3) = 0;
                x_res(4) = 0;
                x_res(5) = x(2);
                x_res(6) = 0;                 
            case "PI"
                x_res(1) = x(1);
                x_res(2) = 0;
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = x(3);
                x_res(6) = 0;                 
            case "PID"
                x_res(1) = x(1);
                x_res(2) = 0;
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = x(3);
                x_res(6) = x(4);                
        end      
    case "I"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x_res(1) = 0;
                x_res(2) = x(1);
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = 0;
                x_res(6) = 0;                
            case "I"
                x_res(1) = 0;
                x_res(2) = x(1);
                x_res(3) = 0;
                x_res(4) = 0;
                x_res(5) = x(2);
                x_res(6) = 0;                 
            case "PI"
                x_res(1) = 0;
                x_res(2) = x(1);
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = x(3);
                x_res(6) = 0;                 
            case "PID"
                x_res(1) = 0;
                x_res(2) = x(1);
                x_res(3) = 0;
                x_res(4) = x(2);
                x_res(5) = x(3);
                x_res(6) = x(4);                
        end     
    case "PI"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = 0;
                x_res(4) = x(3);
                x_res(5) = 0;
                x_res(6) = 0;                
            case "I"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = 0;
                x_res(4) = 0;
                x_res(5) = x(3);
                x_res(6) = 0;                 
            case "PI"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = 0;
                x_res(4) = x(3);
                x_res(5) = x(4);
                x_res(6) = 0;                 
            case "PID"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = 0;
                x_res(4) = x(3);
                x_res(5) = x(4);
                x_res(6) = x(5);                
        end              
    case "PID"
        switch UserInputs.TEF_Controller.Typ
            case "P"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = x(3);
                x_res(4) = x(4);
                x_res(5) = 0;
                x_res(6) = 0;                
            case "I"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = x(3);
                x_res(4) = 0;
                x_res(5) = x(4);
                x_res(6) = 0;                 
            case "PI"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = x(3);
                x_res(4) = x(4);
                x_res(5) = x(5);
                x_res(6) = 0;                 
            case "PID"
                x_res(1) = x(1);
                x_res(2) = x(2);
                x_res(3) = x(3);
                x_res(4) = x(4);
                x_res(5) = x(5);
                x_res(6) = x(6);                
        end 
end

% Ergebnisse der Optimierung ausgeben
fprintf(fileID,'\n\n>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<\n');
fprintf(fileID,'Ergebnisse der Optimierung\n');
fprintf(fileID,'IPC:\n');
fprintf(fileID,'    K_P = %f \n',x_res(1));
fprintf(fileID,'    K_I = %f \n',x_res(2));
fprintf(fileID,'    K_D = %f \n',x_res(3));
fprintf(fileID,'TEF:\n');
fprintf(fileID,'    K_P = %f \n',x_res(4));
fprintf(fileID,'    K_I = %f \n',x_res(5));
fprintf(fileID,'    K_D = %f \n',x_res(6));
fprintf(fileID,'>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<\n');

fprintf('\n>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<\n');
fprintf('Ergebnisse der Optimierung\n');
fprintf('IPC:\n');
fprintf('    K_P = %f \n',x_res(1));
fprintf('    K_I = %f \n',x_res(2));
fprintf('    K_D = %f \n',x_res(3));
fprintf('TEF:\n');
fprintf('    K_P = %f \n',x_res(4));
fprintf('    K_I = %f \n',x_res(5));
fprintf('    K_D = %f \n',x_res(6));
fprintf('>>>>>>>>>>>>>>>>>>>>>><<<<<<<<<<<<<<<<<<<<<\n');

% Text-Datei schließen
fclose(fileID);

% Optimierungshistory anzeigen
disp(history);

% Speichern der Optimierungshistory als .mat-Datei
save(fullfile(OptimizationResultsFolderPath,'History.mat'),'history');

end

