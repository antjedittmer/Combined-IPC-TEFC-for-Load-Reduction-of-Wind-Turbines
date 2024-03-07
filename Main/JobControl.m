function [] = JobControl(UserInputs)
%JOBCONTROL Summary of this function goes here
%   Funktion zum Starten der vom Benutzer geforderten Aufgaben

switch UserInputs.Job.Definition
    case 'createWindPlots'
                
        % Ordner und Pfad zum speichern der Windplots erstellen 
        %    Post_processing-Ordner erstellen 
        if ~exist('Post_processing', 'dir' )                             
            mkdir Post_processing 
        end
        
        t    = datestr(now,'yyyymmdd_HHMM'); %datetime;
        % t.Format         = 'dd-MMM-yy_HH-mm';
        WindPlotsFolderName = append('Windplots_', char(t));
        mkdir('Post_processing',WindPlotsFolderName); 
        WindPlotsFolderPath = fullfile(pwd,'Post_processing',WindPlotsFolderName);
                
        % Windplots erstellen
        for i = 1 : length(UserInputs.WindDataFiles)
            BTSfilePath = strcat('..\FAST_Sim_TEF\5MW-Turbine-Inputfiles\Sub-Inputfiles\', UserInputs.WindDataFiles(i));
            create_FFwind_figure(BTSfilePath,WindPlotsFolderPath);
        end
        
        fprintf('\nPlotfunktion Beendet.\n');
                
    case 'Analyses'
        if UserInputs.TEF_Controller.Switch ~= "variabel" || UserInputs.IPC_Controller.Switch ~= "variabel"
           % kein weiteres Postprocessing durchführen 
           UserInputs.FurtherPostProcessing.PSDanalyse.Do    = 'No';
           UserInputs.FurtherPostProcessing.StatsAnalyse.Do  = 'No';
           UserInputs.FurtherPostProcessing.DELanalyse.Do    = 'No';
           UserInputs.CostFunktion.Do                        = 'No';             
        end                
        [CostsOut, SimRunFolderPath] = main(UserInputs);
        fprintf('\nAnalyse Beendet.\n');
    case 'Optimization'
        optimization(UserInputs); 
        fprintf('\nOptimierung Beendet.\n');
        
    case 'GridSearch'
        GridSearch(UserInputs); 
        fprintf('\nGrid Search Beendet.\n');
        
    otherwise
        fprintf('Ungültige Eingabe für JobDefinition. Wählen sie zwischen Analyses oder Optimization.\n');
        return;               
end

end

