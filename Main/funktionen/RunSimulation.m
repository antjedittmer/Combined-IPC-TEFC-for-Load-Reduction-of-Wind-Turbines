function [SimRunFolderPath] = RunSimulation(SimConfig, FAST_OutputFilePath, PostProcessingFolderPath)
%RUNSIMULATION Summary of this function goes here
%   Detailed explanation goes here

%% Entpacken der Config-Daten und speichern der Vaiabelen im Workspace
Simulink_FileName = SimConfig.Simulink_FilePath;

assignin('base','TMax', SimConfig.TMax);
assignin('base','FAST_InputFileName', SimConfig.FAST_InputFileName);

% Laden der Workspacevariablen für den Basis-Controller
LoadDataForCPC(SimConfig);

% GenTq
switch(SimConfig.controller.GenTq.switch)
    case 'on'
        SimConfig.controller.GenTq.GenTq_Cotroller_switch = 1;
        GenTq_Cotroller_status = 'on';
    case 'off'
        SimConfig.controller.GenTq.GenTq_Cotroller_switch = 0;
        GenTq_Cotroller_status = 'off';
    otherwise
        fprintf('Fehler! Ungültige Eingabe für GenTq-Controller-Switch. \n'); 
        return
end 

% CPC 
switch(SimConfig.controller.CPC.switch)
    case 'on'
        SimConfig.controller.CPC.CPC_Cotroller_switch = 1;
        CPC_Cotroller_status = 'on';
    case 'off'
        SimConfig.controller.CPC.CPC_Cotroller_switch = 0;
        CPC_Cotroller_status = 'off';
    otherwise
        fprintf('Fehler! Ungültige Eingabe für CPC-Controller-Switch. \n'); 
        return
end         
        
% IPC
switch(SimConfig.controller.IPC.switch)
    case 'on'
        SimConfig.controller.IPC.IPC_Cotroller_switch = 1;
        IPC_Cotroller_status = 'on';    
        IPC_loop = 1;
    case 'off'
        SimConfig.controller.IPC.IPC_Cotroller_switch = 0;
        IPC_Cotroller_status = 'off';  
        IPC_loop = 1;
    case 'variabel'
        IPC_loop = 2;
        IPC_Cotroller_status = 'off';    
    otherwise
        fprintf('Fehler! Ungültige Eingabe für IPC-Controller-Switch. \n'); 
        return
end 


% TEF
switch(SimConfig.controller.TEF.switch)
    case 'on'
        SimConfig.controller.TEF.TEF_Cotroller_switch = 1;
        assignin('base','SimConfig', SimConfig);
        TEF_loop = 1;
        TEF_Cotroller_status = 'on';
    case 'off'
        SimConfig.controller.TEF.TEF_Cotroller_switch = 0;
        assignin('base','SimConfig', SimConfig);
        TEF_loop = 1;
        TEF_Cotroller_status = 'off';
    case 'variabel'
        TEF_loop = 2;
        TEF_Cotroller_status = 'off';
    otherwise
        fprintf('Fehler! Ungültige Eingabe für TEF-Controller-Switch. \n'); 
        return
end

% Anzahl der Simulationen die insgesamt durchgeführt werden berechnen und Anzeigen
if (SimConfig.controller.TEF.switch == "variabel") && (SimConfig.controller.IPC.switch == "variabel")
    SumSim = length(SimConfig.WindData)*4;
elseif ((SimConfig.controller.TEF.switch ~= "variabel") && (SimConfig.controller.IPC.switch == "variabel")) || ((SimConfig.controller.TEF.switch == "variabel") && (SimConfig.controller.IPC.switch ~= "variabel"))
    SumSim = length(SimConfig.WindData)*2;
else
    SumSim = length(SimConfig.WindData);
end
fprintf('Es werden insgesamt %d Simulationen durchgeführt. \n', SumSim);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Sim-Run-Ordner erstellen
t    = datestr(now,'yyyymmdd_HHMM'); %datetime;
% t.Format         = 'dd-MMM-yy_HH-mm';
SimRunFolderName = append('Simulation_Run_at_', char(t));
mkdir('Post_processing', SimRunFolderName);
SimRunFolderPath = fullfile(PostProcessingFolderPath, SimRunFolderName);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


NumSim = 1;                                                                % Nummer der aktuellen Simulation
for k = 1 : length(SimConfig.WindData)                                     % loop über Windtestfälle
    %% Anpassen der InflowWind-Datei
    WindDataFileName = Edit_InflowWind_V2(SimConfig.WindData, k, SimConfig.InflowWindFilePath);

    %% Ergebnis-Ordner im Sim-Run-Ornder erstellen
    ResultsFolderName = 'Results_';
    mkdir(SimRunFolderPath, append(ResultsFolderName,WindDataFileName)); 
    FAST_OUT_ArchivFolderPath_id = fullfile(SimRunFolderPath, append(ResultsFolderName,WindDataFileName));


    %% Simulationen Durchführen
    for i = 1 : TEF_loop                                                   % loop über TEF-Controller Einstellungen 
        
        for j = 1 : IPC_loop                                               % loop über TPC-Controller Einstellungen 
        
            % Abfragen der Controllereinstellungen (Wird nur gemacht, wenn
            % beide Switches für den TEF- und dem IPC-Regler auf variabel
            % stehen
 
            if (i == 1) && (TEF_loop == 2) && (j == 1) && (IPC_loop == 2)  % Fall TEF off und IPC off
                SimConfig.controller.TEF.TEF_Cotroller_switch = 0;
                TEF_Cotroller_status = 'off';
                
                SimConfig.controller.IPC.IPC_Cotroller_switch = 0;
                IPC_Cotroller_status = 'off';
                
                assignin('base','SimConfig', SimConfig);
                
            elseif (i == 1) && (TEF_loop == 2) && (j == 2) && (IPC_loop == 2) % Fall TEF off und IPC om
                SimConfig.controller.TEF.TEF_Cotroller_switch = 0;
                TEF_Cotroller_status = 'off';
                
                SimConfig.controller.IPC.IPC_Cotroller_switch = 1;
                IPC_Cotroller_status = 'on';
                
                assignin('base','SimConfig', SimConfig);
                
            elseif (i == 2) && (TEF_loop == 2) && (j == 1) && (IPC_loop == 2) % Fall TEF on und IPC off
                SimConfig.controller.TEF.TEF_Cotroller_switch = 1;
                TEF_Cotroller_status = 'on';              
                
                SimConfig.controller.IPC.IPC_Cotroller_switch = 0;
                IPC_Cotroller_status = 'off';
                
                assignin('base','SimConfig', SimConfig);
                
            elseif (i == 2) && (TEF_loop == 2) && (j == 2) && (IPC_loop == 2) % Fall TEF on und IPC on
                SimConfig.controller.TEF.TEF_Cotroller_switch = 1;
                TEF_Cotroller_status = 'on';
                
                SimConfig.controller.IPC.IPC_Cotroller_switch = 1;
                IPC_Cotroller_status = 'on';
                
                assignin('base','SimConfig', SimConfig);
            end
            
            
            % Abfragen der Controllereinstellungen, wenn der TEF-Switch auf
            % variabel steht und der IPC-Switch auf on oder off
            if (i == 1) && (TEF_loop == 2) && (IPC_loop == 1)              % Fall IPC on oder off und TEF off
                SimConfig.controller.TEF.TEF_Cotroller_switch = 0;
                assignin('base','SimConfig', SimConfig);
                TEF_Cotroller_status = 'off';
            elseif (i == 2) && (TEF_loop == 2) && (IPC_loop == 1)          % Fall IPC on oder off und TEF on
                SimConfig.controller.TEF.TEF_Cotroller_switch = 1;
                assignin('base','SimConfig', SimConfig);
                TEF_Cotroller_status = 'on';
            end
            
            
            % Abfragen der Controllereinstellungen, wenn der IPC-Switch auf
            % variabel steht und der TEF-Switch auf on oder off
            if (j == 1) && (TEF_loop == 1) && (IPC_loop == 2)              % Fall TEF on oder off und IPC off
                SimConfig.controller.IPC.IPC_Cotroller_switch = 0;
                assignin('base','SimConfig', SimConfig);
                IPC_Cotroller_status = 'off';
                
            elseif (j == 2) && (TEF_loop == 1) && (IPC_loop == 2)          % Fall TEF on oder off und IPC on
                SimConfig.controller.IPC.IPC_Cotroller_switch = 1;
                assignin('base','SimConfig', SimConfig);
                IPC_Cotroller_status = 'on';
            end
            



            % Starten der Simulation
            fprintf('-------------------------------------------------------------\n');
            fprintf('Simulation Nr. %d von %d \n', NumSim, SumSim);
            fprintf('Startzeitpunkt: %s \n', datetime);
            fprintf('Die Simulation wird in der folgenden Konfiguration gestartet:\n');
            fprintf('   Winddatei: %s \n', SimConfig.WindData(k));
            fprintf('   Simulationszeit = %d s\n', SimConfig.TMax);
            fprintf('   Cotroller Konfigurationen: \n');
            fprintf('      GenTq Cotroller Status = %s \n', GenTq_Cotroller_status);       
            fprintf('      CPC   Cotroller Status = %s \n', CPC_Cotroller_status);
            fprintf('      IPC   Cotroller Switch = %s \n', SimConfig.controller.IPC.switch);
            fprintf('      IPC   Cotroller Status = %s \n', IPC_Cotroller_status);        
            fprintf('      TEF   Cotroller Switch = %s \n', SimConfig.controller.TEF.switch);        
            fprintf('      TEF   Cotroller Status = %s \n', TEF_Cotroller_status);
            fprintf('      PID-Gains IPC-Cotroller \n');
            fprintf('         K_P = %f \n', SimConfig.controller.IPC.K_P);
            fprintf('         K_I = %f \n', SimConfig.controller.IPC.K_I);
            fprintf('         K_D = %f \n', SimConfig.controller.IPC.K_D);
            fprintf('      PID-Gains TEF-Cotroller \n');
            fprintf('         K_P = %f \n', SimConfig.controller.TEF.K_P);
            fprintf('         K_I = %f \n', SimConfig.controller.TEF.K_I);
            fprintf('         K_D = %f \n', SimConfig.controller.TEF.K_D);

            NumSim = NumSim + 1;
            tic
            sim(Simulink_FileName,[0,SimConfig.TMax]);

            Sim_dauer = seconds(toc);
            Sim_dauer.Format = 'hh:mm:ss';
            fprintf(' > Simulation Beendet \n');
            fprintf('Benötigte Zeit zum Ausführen der Simulation: %s \n', Sim_dauer);
            fprintf('-------------------------------------------------------------\n');


            % FAST-OUT-Datei in FAST_OUT_Archiv-Ordner kopieren 
            copyfile(FAST_OutputFilePath, FAST_OUT_ArchivFolderPath_id);

            % Umbenennen der FAST-Outputdatei
            FAST_OUT_File_rename = [FAST_OUT_ArchivFolderPath_id filesep SimConfig.FAST_OutputFileName];
            [~, FASTOutputFileName] = fileparts(SimConfig.FAST_OutputFileName);
            FAST_OUT_File_newName = [FAST_OUT_ArchivFolderPath_id filesep FASTOutputFileName '_TEF_' TEF_Cotroller_status '_IPC_' IPC_Cotroller_status '.out'];
            movefile(FAST_OUT_File_rename, FAST_OUT_File_newName);

            clear FAST_OUT_File_newName FAST_OUT_File_rename

            % Die Simulinkvariablen OutData und Flap_Angles in Archivordner speichern und umbenennen
            %OutData = [];
            %Flap_Angles = [];
            save([FAST_OUT_ArchivFolderPath_id filesep 'OutData_TEF_' TEF_Cotroller_status '_IPC_' IPC_Cotroller_status '.mat'] , 'OutData')
            save([FAST_OUT_ArchivFolderPath_id filesep 'Flap_Angles_TEF_' TEF_Cotroller_status '_IPC_' IPC_Cotroller_status '.mat'] , 'Flap_Angles')
            save([FAST_OUT_ArchivFolderPath_id filesep 'Pitch_Actuator_Power_TEF_' TEF_Cotroller_status '_IPC_' IPC_Cotroller_status '.mat'] , 'PichActuatorPower')
            save([FAST_OUT_ArchivFolderPath_id filesep 'PowerReferenceTracking_TEF_' TEF_Cotroller_status '_IPC_' IPC_Cotroller_status '.mat'] , 'PowerReferenceTracking')
            OutList = evalin('base', 'OutList');
            save([FAST_OUT_ArchivFolderPath_id filesep 'OutList.mat'] , 'OutList');
            
        end                                                                % Ende des IPC-Loops

    end                                                                    % Ende des TEF-Loops

end                                                                        % Ende des Loops über Windtestfälle

end                                                                        % Ende der RunSimulation-Funktion 

