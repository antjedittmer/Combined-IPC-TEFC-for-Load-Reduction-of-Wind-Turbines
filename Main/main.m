function [CostsOut, SimRunFolderPath] = main(UserInputs,x)
%MAIN Summary of this function goes here
%   Detailed explanation goes here
fprintf('\nMain-Programm gestartet.\n');
LogFileName = 'Log.text';
diary(LogFileName);                                                             % Ausgaben im Command Window in Text-Datei Speichern
diary on                                                                   % Aufzeichnung der Command Window-Ausgaben starten

tic
% Eingaben Überprüfen
check1 = matches(UserInputs.ActionCommands.Simulations,["Yes","No"]);
check2 = matches(UserInputs.ActionCommands.MCrunch,["Yes","No"]);
check3 = matches(UserInputs.FurtherPostProcessing.PSDanalyse.Do,["Yes","No"]);

if check1 == 0
    fprintf('Fehler! Ungültige Eingabe für DoSimulations.\n');
    return;
end

if check2 == 0
    fprintf('Fehler! Ungültige Eingabe für DoMCrunchAnalyse.\n');
    return;
end

if check3 == 0
    fprintf('Fehler! Ungültige Eingabe für DoPSDanalyse.\n');
    return;
end

%/////////////////////////////////////////////////////////////////////////%
%                          - - - Setup - - - 

%%   Pfade speichern  
%    Pfad zum Main-Ordner speichern
mainFolderPath = pwd;
%    Pfad zum Programmordner speichern
programm_filepath = fullfile(fileparts(pwd),'FAST_Sim_TEF');

%%   Pfade zu Input-Datein angeben
%    Simulink-Datei festlegen 
Simulink_FilePath = fullfile(programm_filepath, 'simulink', UserInputs.InputFileNames.Simulink);

%    FAST-Eingabedatei festlegen 
FAST_InputFileName = fullfile(programm_filepath, '5MW-Turbine-Inputfiles', UserInputs.InputFileNames.FAST);

%    InflowWind-Eingabedatei festlegen 
InflowWind_InputFilePath = fullfile(programm_filepath, '5MW-Turbine-Inputfiles', 'Sub-Inputfiles', UserInputs.InputFileNames.InflowWind);

%    Pfad zur MCrunch-Inputdatei angeben 
MCrunch_InputFilePath = fullfile(programm_filepath, 'mcru_files', UserInputs.InputFileNames.MCrunch);

%%   Pfad zur FAST-OUT-Datei angeben   
[~, FASTOutputFileName] = fileparts(UserInputs.InputFileNames.FAST);
FASTOutputFileName      = strcat(FASTOutputFileName, '.SFunc.out');
FAST_OutputFilePath     = fullfile( programm_filepath, '5MW-Turbine-Inputfiles', FASTOutputFileName);

%%   Ordner erstellen   
%    Post_processing-Ordner erstellen 
if ~exist('Post_processing', 'dir' )                              % Überprüfen, ob Ordner bereits existiert
   mkdir Post_processing 
end
PostProcessingFolderPath = fullfile(mainFolderPath, 'Post_processing'); 

%%   Alle Unterordner einbinden  
addpath(genpath(programm_filepath)); 
addpath(genpath(mainFolderPath));


%%
%/////////////////////////////////////////////////////////////////////////%
%              - - - Durchfuehren der Simulationen - - - 

% Definiren der Simulationskonfiguration 
SimConfig.TMax                = UserInputs.SimTime; 
SimConfig.Simulink_FilePath   = Simulink_FilePath;
SimConfig.FAST_InputFileName  = FAST_InputFileName;
SimConfig.FAST_OutputFileName = FASTOutputFileName;

SimConfig.WindData = UserInputs.WindDataFiles;
SimConfig.InflowWindFilePath = InflowWind_InputFilePath;

% GenTq-Regler
SimConfig.controller.GenTq.switch = UserInputs.GenTq_Controller.Switch;

% CPC-Regler 
SimConfig.controller.CPC.switch            = UserInputs.CPC_Controller.Switch;
SimConfig.controller.CPC.InitialPitchAngle = UserInputs.CPC_Controller.InitialPitchAngle;

SimConfig.controller.TEF.TEF_OLvalue = UserInputs.TEF.TEF_OLvalue;

switch UserInputs.Optimization.Do
    case "false"
        % Reglerschalter
        SimConfig.controller.IPC.switch = UserInputs.IPC_Controller.Switch;
        SimConfig.controller.TEF.switch = UserInputs.TEF_Controller.Switch;
        % Reglergains
        switch UserInputs.IPC_Controller.Typ
            case "P"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0; 
                    case "I"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;                        
                    case "PI"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;                         
                    case "PID"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = UserInputs.TEF_Controller.K_D;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;                                                
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end       
            case "I"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0; 
                    case "I"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                        
                    case "PI"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                         
                    case "PID"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = UserInputs.TEF_Controller.K_D;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                                                
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                      
            case "PI"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0; 
                    case "I"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                        
                    case "PI"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                         
                    case "PID"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = UserInputs.TEF_Controller.K_D;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = 0;                                                
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                       
            case "PID"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = UserInputs.IPC_Controller.K_D; 
                    case "I"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = UserInputs.IPC_Controller.K_D;                         
                    case "PI"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = 0;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = UserInputs.IPC_Controller.K_D;                          
                    case "PID"
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = UserInputs.TEF_Controller.K_P;
                        SimConfig.controller.TEF.K_I    = UserInputs.TEF_Controller.K_I;
                        SimConfig.controller.TEF.K_D    = UserInputs.TEF_Controller.K_D;
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = UserInputs.IPC_Controller.K_P;
                        SimConfig.controller.IPC.K_I    = UserInputs.IPC_Controller.K_I;
                        SimConfig.controller.IPC.K_D    = UserInputs.IPC_Controller.K_D;                                                 
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                      
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der IPC ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end
        
    case "true"
        % Reglerschalter
        SimConfig.controller.TEF.switch = UserInputs.TEF_Controller.Switch;
        SimConfig.controller.IPC.switch = UserInputs.IPC_Controller.Switch;        
        % Reglergains
        switch UserInputs.IPC_Controller.Typ
            case "P"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "I"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = x(2);
                        SimConfig.controller.TEF.K_D    = 0;                         
                    case "PI"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = x(3);
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "PID"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = 0;
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = x(3);
                        SimConfig.controller.TEF.K_D    = x(4);                        
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end     
            case "I"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = x(1);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "I"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = x(1);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = x(2);
                        SimConfig.controller.TEF.K_D    = 0;                         
                    case "PI"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = x(1);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = x(3);
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "PID"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = 0;
                        SimConfig.controller.IPC.K_I    = x(1);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(2);
                        SimConfig.controller.TEF.K_I    = x(3);
                        SimConfig.controller.TEF.K_D    = x(4);                        
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                      
            case "PI"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(3);
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "I"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = x(3);
                        SimConfig.controller.TEF.K_D    = 0;                         
                    case "PI"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(3);
                        SimConfig.controller.TEF.K_I    = x(4);
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "PID"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = 0;
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(3);
                        SimConfig.controller.TEF.K_I    = x(4);
                        SimConfig.controller.TEF.K_D    = x(5);                        
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                       
            case "PID"
                switch UserInputs.TEF_Controller.Typ
                    case "P"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = x(3);
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(4);
                        SimConfig.controller.TEF.K_I    = 0;
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "I"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = x(3);
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = 0;
                        SimConfig.controller.TEF.K_I    = x(4);
                        SimConfig.controller.TEF.K_D    = 0;                         
                    case "PI"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = x(3);
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(4);
                        SimConfig.controller.TEF.K_I    = x(5);
                        SimConfig.controller.TEF.K_D    = 0;                        
                    case "PID"
                        % IPC-Regler
                        SimConfig.controller.IPC.K_P    = x(1);
                        SimConfig.controller.IPC.K_I    = x(2);
                        SimConfig.controller.IPC.K_D    = x(3);
                        % TEF-Regler
                        SimConfig.controller.TEF.K_P    = x(4);
                        SimConfig.controller.TEF.K_I    = x(5);
                        SimConfig.controller.TEF.K_D    = x(6);                        
                    otherwise
                        fprintf('\nDie Eingabe für den Reglertyp der TEF ist ungültig. (P, I, PI, oder PID)\n');
                        return;
                end                    
            otherwise
                fprintf('\nDie Eingabe für den Reglertyp der IPC ist ungültig. (P, I, PI, oder PID)\n');
                return;
        end        
end


% Durchführen der Simulation
if UserInputs.ActionCommands.Simulations == "Yes"
    ErrorFlag = 0;
    if UserInputs.Optimization.Do == "true"
        try
            clear mex % clear mex to avoid crash when starting the next time ('..memory already allocated..')
            Edit_fst(FAST_InputFileName,UserInputs.StartDatalogging);
            SimRunFolderPath = RunSimulation(SimConfig, FAST_OutputFilePath, PostProcessingFolderPath);
            clear mex % clear mex to avoid crash when starting the next time ('..memory already allocated..')
        catch ME
            warning('  >>>>>  In der Simulation ist ein Fehler aufgetreten!');
            disp(ME.message);
            ErrorFlag = 1;
        end
    else
        clear mex % clear mex to avoid crash when starting the next time ('..memory already allocated..')
        Edit_fst(FAST_InputFileName,UserInputs.StartDatalogging);
        SimRunFolderPath = RunSimulation(SimConfig, FAST_OutputFilePath, PostProcessingFolderPath);
        clear mex % clear mex to avoid crash when starting the next time ('..memory already allocated..')
    end
else
    SimRunFolderPath = [];
end

if ErrorFlag == 0                                                           % Wenn es einen Fahler in der Simulation gab, darf kein Postprocessing durchgeführt werden und der Ausgabe der Kostenfunktion wird NaN zugewiesen 

    %%
    %/////////////////////////////////////////////////////////////////////////%
    %                     - - - Post processing - - -
    %                     Datenauswertung mit MCrunch
    if UserInputs.ActionCommands.MCrunch == "Yes"

    if (UserInputs.ActionCommands.MCrunch == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        RunMCrunch(SimRunFolderPath, MCrunch_InputFilePath, mainFolderPath,UserInputs);
        com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser') % schließen des Web Browser Fensters
        system('taskkill /F /IM EXCEL.EXE');                                   % Excel-Tasks die von MCrunch gestartet wurden beenden, da sonnst der Arbeitsspeicher voll läuft und der Prozessor überlastet wird
    elseif (UserInputs.ActionCommands.MCrunch == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        RunMCrunch(UserInputs.ActionCommands.MCrunchAnayseFolder, MCrunch_InputFilePath, mainFolderPath,UserInputs);
        com.mathworks.mlservices.MatlabDesktopServices.getDesktop.closeGroup('Web Browser') % schließen des Web Browser Fensters
        system('taskkill /F /IM EXCEL.EXE');                                   % Excel-Tasks die von MCrunch gestartet wurden beenden, da sonnst der Arbeitsspeicher voll läuft und der Prozessor überlastet wird
    else
        CostsOut = [];
    end 


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Weiteres Post-processing in Matlab

    % Prüfen, ob Log.text im SimRunFolderPath oder SimulationResultsFolderPath
    % existiert und ggf leere Log.text Datei erzeugen
    if UserInputs.ActionCommands.Simulations == "Yes"
        if isfile(fullfile(SimRunFolderPath,'Log.text')) ~= 1 
            fid = fopen(fullfile(SimRunFolderPath, LogFileName), 'w');
            fclose(fid);
        end
    end

    % PSD-Analyse
    if (UserInputs.FurtherPostProcessing.PSDanalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        AnalysePSDout = AnalysePSD_2(SimRunFolderPath, UserInputs.FurtherPostProcessing.PSDanalyse.BaselineCase ,UserInputs.Optimization.BaselineCaseFolderPath, UserInputs.Optimization.Do);
    elseif (UserInputs.FurtherPostProcessing.PSDanalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        AnalysePSDout = AnalysePSD_2(UserInputs.FurtherPostProcessing.PSDanalyse.SimulationResultsFolderPath, UserInputs.FurtherPostProcessing.PSDanalyse.BaselineCase, [], "false");
    end

    % Statistik-Analyse
    if (UserInputs.FurtherPostProcessing.StatsAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        AnalyseStatsout = AnalyseStats_4(SimRunFolderPath, UserInputs.FurtherPostProcessing.StatsAnalyse.BaselineCase, UserInputs.Optimization.BaselineCaseFolderPath, UserInputs.Optimization.Do, UserInputs.FurtherPostProcessing.StatsAnalyse.StatsChannelName);
    elseif (UserInputs.FurtherPostProcessing.StatsAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        AnalyseStatsout = AnalyseStats_4(UserInputs.FurtherPostProcessing.StatsAnalyse.SimulationResultsFolderPath, UserInputs.FurtherPostProcessing.StatsAnalyse.BaselineCase, [], "false", UserInputs.FurtherPostProcessing.StatsAnalyse.StatsChannelName);
    end

    % DEL-Analyse
    if (UserInputs.FurtherPostProcessing.DELanalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        AnalyseDELout = AnalyseDEL_2_max(SimRunFolderPath, UserInputs.FurtherPostProcessing.DELanalyse.BaselineCase, UserInputs.FurtherPostProcessing.DELanalyse.Channels, UserInputs.Optimization.BaselineCaseFolderPath, UserInputs.Optimization.Do);
    elseif (UserInputs.FurtherPostProcessing.DELanalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        AnalyseDELout = AnalyseDEL_2_max(UserInputs.FurtherPostProcessing.DELanalyse.SimulationResultsFolderPath, UserInputs.FurtherPostProcessing.DELanalyse.BaselineCase, UserInputs.FurtherPostProcessing.DELanalyse.Channels,[],"false");
    end
    

    % Power-Analyse
    if (UserInputs.FurtherPostProcessing.PowerAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        PowerReferenceAnalyseOut = PowerReferenceAnalyse(SimRunFolderPath, UserInputs.FurtherPostProcessing.PowerAnalyse.BaselineCase,UserInputs.Optimization.BaselineCaseFolderPath, UserInputs.Optimization.Do, UserInputs);
    elseif (UserInputs.FurtherPostProcessing.PowerAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        PowerReferenceAnalyseOut = PowerReferenceAnalyse(UserInputs.FurtherPostProcessing.PowerAnalyse.SimulationResultsFolderPath, UserInputs.FurtherPostProcessing.PowerAnalyse.BaselineCase,UserInputs.Optimization.BaselineCaseFolderPath, UserInputs.Optimization.Do, UserInputs);
    end
        
    % Actuator-Power-Analyse
    if (UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "Yes")
        ActuatorPowerAnalyseOut = ActuatorPowerAnalyse(SimRunFolderPath, UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.BaselineCase, UserInputs.Optimization.BaselineCaseFolderPath,  UserInputs.Optimization.Do, UserInputs);
    elseif (UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do == "Yes") && (UserInputs.ActionCommands.Simulations == "No")
        ActuatorPowerAnalyseOut = ActuatorPowerAnalyse(UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.SimulationResultsFolderPath, UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.BaselineCase, UserInputs.Optimization.BaselineCaseFolderPath,  UserInputs.Optimization.Do, UserInputs); 
    end

    %/////////////////////////////////////////////////////////////////////////%
    %              - - - Auswerten einer Kostenfunktion - - -

%     if (UserInputs.CostFunktion.Do == "Yes") && (UserInputs.FurtherPostProcessing.PSDanalyse.Do == "Yes") && (UserInputs.FurtherPostProcessing.StatsAnalyse.Do == "Yes") && (UserInputs.FurtherPostProcessing.DELanalyse.Do == "Yes")
%         CostsOut = CostFunctionDEL(AnalysePSDout,AnalyseStatsout,AnalyseDELout,UserInputs.CostFunktion.Testcase);
%     else
%         CostsOut = [];
%     end
    
    if (UserInputs.CostFunktion.Do == "Yes") && (UserInputs.FurtherPostProcessing.PSDanalyse.Do == "Yes") && (UserInputs.FurtherPostProcessing.StatsAnalyse.Do == "Yes") && (UserInputs.FurtherPostProcessing.DELanalyse.Do == "Yes")
        CostsOut = CostFunctionDELAllMoments(AnalysePSDout,AnalyseStatsout,AnalyseDELout,UserInputs.CostFunktion.Testcase);
    else
        CostsOut = [];
    end
    
    

    end

else
    CostsOut = NaN;
end



%/////////////////////////////////////////////////////////////////////////%
% - - - Bei Optimierung, Evaluation-History aufzeichnen und speichern - - -
if UserInputs.Optimization.Do == "true"
    RecordFunEvalHistory(CostsOut, SimConfig, UserInputs);   
end


%/////////////////////////////////////////////////////////////////////////%
% Ende der Main-Funktion

% löschen der config-Daten aus dem Workspace
clear TMax FAST_InputFileName SimConfig

Programm_dauer = seconds(toc);
Programm_dauer.Format = 'hh:mm:ss';
fprintf('\n------------------------------------------------------------\n')
fprintf('Main-Programm Beendet.\n');
fprintf('Benötigte Zeit zum Ausführen des Programms: %s \n', Programm_dauer);
fprintf('------------------------------------------------------------\n')

diary off                                                                  % Aufzeichnung der Command Window-Ausgaben beenden
if exist('SimRunFolderPath','var') == 1
    movefile(fullfile(mainFolderPath, LogFileName), SimRunFolderPath,'f');     % Verschieben der Log-Datei in den Simulationsordner
else
    movefile(fullfile(mainFolderPath, LogFileName), UserInputs.ActionCommands.MCrunchAnayseFolder,'f');
end

restoredefaultpath
system('taskkill /F /IM EXCEL.EXE');                                       % Excel-Tasks gestartet wurden beenden, da sonnst der Arbeitsspeicher voll läuft und der Prozessor überlastet wird

end

