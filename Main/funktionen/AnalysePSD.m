function [AnalysePSDout] = AnalysePSD(SimRunFolderPath,BaselineCase)
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
 
 for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
    AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
    ExcelFileName = 'Analyse_PSDs.xls';

    sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
    BaselineCaseStatus = "Fslse";

    for i = 2 : length(sheets)
        %SheetName = sheets(i);
        
        % Daten aus PSD auslesen
        %[pks(:,i-1) , ~, intPSD(i-1)] = ExtractPSD(AnlyseFolderPath, ExcelFileName, SheetName);  
        
        % Pruefen, ob BaselineCase in sheets enthalten ist
        if sheets(i) == BaselineCase && BaselineCaseStatus == "Fslse"
            BaselineCaseStatus = "True";
            BaselineIndex = i-1;
            fprintf('Der Referenzfall wurde gefunden.\n');
        end

    end
    
    if BaselineCaseStatus == "Fslse"
        fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
        AnalysePSDout = [];
        return;
    end
    
    if (length(sheets) >= 3) && (BaselineCaseStatus == "True")
        % Daten aus PSD auslesen
        for i = 2 : length(sheets)
            [pks(:,i-1) , ~, intPSD(i-1)] = ExtractPSD(AnlyseFolderPath, ExcelFileName, sheets(i));  
            %results(z-LoopStart+1).IntegralPSD = intPSD;
        end
        
        % Relative Änderungen der Maxima berechnen
        pks_size = size(pks);
        for i = 1 : pks_size(2)
            rel_delta_pks(:,i) = 100*(pks(:,i) - pks(:,BaselineIndex)) ./ pks(:, BaselineIndex);
            rel_delta_intPSD(i) = 100*(intPSD(i) - intPSD(BaselineIndex)) ./ intPSD(BaselineIndex);
            %results(z-LoopStart+1).RelDeltaP   = rel_delta_pks;
            %results(z-LoopStart+1).RelDeltaInt = rel_delta_intPSD;
        end 
        
        % Ergebnisse Zusammenfassen
        results.IntegralPSD = intPSD;
        results.RelDeltaP   = rel_delta_pks;
        results.RelDeltaInt = rel_delta_intPSD;
        
        rel_delta_pks_size = size(rel_delta_pks);
        %disp(rel_delta_pks_size)
        % Ausgabe der Ergebnisse
        fprintf('Simulationsordner: %s \n', folderNames(z).folder);
        fprintf('Windtestfall: %s \n', folderNames(z).name);
        fprintf('Der Referenzfall ist: %s\n', BaselineCase);
        fprintf('Relative Änderungen in P im Vergleich zum Referenzfall %s:\n', BaselineCase);
        fprintf('-----------------------------');
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
        
    end
    
    % Zusammenfassen der Ergebnisse in Tabelle    
    %Tsheets = table(results.sheets, 'VariableNames',{'Sheets'})
    %for i = 1 : length(results.IntegralPSD)
    %TIntegralPSD = table(results.IntegralPSD(i), 'VariableNames',results.sheets(i));
    %end
    %TRelDeltaP = table(results.RelDeltaP, 'VariableNames',{'RelDeltaP'})
    %TRelDeltaInt = table(results.RelDeltaInt, 'VariableNames',{'RelDeltaInt'})
         
    %T = table(results.sheets, 'VariableNames',{'Sheets'})
    
    % Erstellen des Outputs
    results.sheets = sheets(2:end);
    AnalysePSDout.(sprintf('%s',folderNames(z).name)) = results; 
    
    
     
 end

end

