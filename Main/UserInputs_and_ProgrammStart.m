%% Skript zum Angeben der User-Inputs und zum Starten des Programms
%=========================================================================%
% Alle Variablen Löschen und alle Fenster schließen                        % Programm aus dem Main-Ordner starten!!!
diary off
clc;
clear 
close all
restoredefaultpath
%=========================================================================%
%/////////////////////////////////////////////////////////////////////////%
%             - - - Benutzereingaben ab hier vornehmen - - - 
Simulink_FileName        = 'ClosedLoop_V5_2020b.slx'; 
FAST_FileName            = '5MW_Land.fst';
MCrunch_InputFileName    = 'Analyse.mcru';
InflowWind_InputFileName = 'NRELOffshrBsline5MW_InflowWind_12mps.dat';
Simulationzeit           = 660;
StartzeitDatalogging     = 0.1*Simulationzeit;

%                    - - - Aufgabendefinition - - -
JobDefinition        =   'Analyses';   %      'Optimization'; %                               % 'Analyses', 'Optimization','createWindPlots', 'GridSearch'

%                    - - - Optimierungseinstellungen Generell - - -
OptimizationTestcase     = "5MW_Land.SFunc_TEF_on_IPC_on";
OptimizationFunction     = "fminsearch";                                       % "fminsearch" oder "fmincon"
OptimizationStopCriteria = "MaxFunEvals";                                    % "MaxFunEvals" oder "MaxIter"
MaxIterations            = 3;
MaxFunctionEvaluations   = 250;

%               - - - Optimierungseinstellungen für fmincon - - -
fminconLowerBound = [-4, -4, -4, -4, -4, -4]; 
fminconUpperBound = [ 4,  4,  4,  4, 4,  4];
% Schema            [IPC_KP, IPC_KI, IPC_KD, TEF_KP, TEF_KI, TEF_KD]; 
DiffMaxChange = 0.01;      % Maximum change in variables for finite-difference gradients (a positive scalar).
DiffMinChange = 0.0001;    % Minimum change in variables for finite-difference gradients (a positive scalar).
UseNonlcon    = 'Yes';                                                         % 'Yes' oder 'No' Use TowerDELs as nonlinear constraints
Nebenbedingung = "TowerDELs";                                      % "TowerDELs_UND_Power" oder "Power" oder "TowerDELs"

%               - - - Grid-Search-Einstellungen - - -                 
IPC_KI_GridUpperBound = 4;
IPC_KI_GridLowerBound = 0;
IPC_KI_GridStep       = 0.5;
TEF_KP_GridUpperBound = 4;
TEF_KP_GridLowerBound = 0;
TEF_KP_GridStep       = 0.5;
MakeUnsymetricGrid    = "No";
TEF_KP_ExpandLowerBoundto = 0; 
IPC_KI_ExpandLowerBoundto = 0;

%                        - - - Simulation - - - 
% Simulationen durchführen?
DoSimulations = 'Yes';                                                     % 'Yes' oder 'No'

%                      - - - Post-Processing - - - 
% MCrunch Analyse?
DoMCrunchAnalyse = 'Yes';                                                  % 'Yes' oder 'No'
% Angeben des Pfads zum Ordner mit den Simulationsergebnissen. 
% Wenn keine Siulationen durchgeführt werden sollen und statdessen nur 
% eine MCrunch analyse durchgeführt werden soll, dann werden die Dateien im
% folgenden Pfad für die Analyse verwendet.
SimulationResultsFolderPath = '.\Post_processing\Simulation_Run_at_14-Dec-22_17-41-35';                                             
% Further Post-Processing
DoPSDanalyse   = 'Yes';                                                      % 'Yes' oder 'No'
DoStatsAnalyse = 'Yes';                                                      % 'Yes' oder 'No'
DoDELanalyse   = 'Yes';                                                      % 'Yes' oder 'No'
StatsChannel = ["RootMyc1", "TwrBsMyt"];
ChannelNames = ["RootMyc1","RootMyc2", "RootMyc3","TwrBsMyt","TwrBsMxt","TwrBsMzt",...
    "YawBrMxp","YawBrMyp","YawBrMzp"];
Channelgruppe = struct;
for idx = 1: length(ChannelNames)
     Channelgruppe(idx).Gruppe = ChannelNames(idx);
end
    
DoActuatorPowerAnalyse = 'Yes';
DoPowerAnalyse         = 'Yes';

BaselineCase   = "5MW_Land.SFunc_TEF_off_IPC_off";

%                      - - - Kostenfunktion  - - - 
% Kostenfunktion Auswerten
DoCostAnalyse = 'Yes';                                                      % 'Yes' oder 'No'
Testcase      = "5MW_Land.SFunc_TEF_on_IPC_on";

%                    - - - Reglereinstellungen - - - 
% Eingaben für Generator-Torque-Regler
GenTq_Switch = 'on';                                                       % 'on' oder 'off'

% Eingaben für CPC-Regler
CPC_Switch = 'on';                                                         % 'on' oder 'off' (Wenn off, dann ist auch der IPC-Regler off)
CP_Initial_Pitch_Angle = 20;                                               % in grad (Durch die PT1 transferfunktionen im Aktuatormodell und die Rate-Limiter wird jedoch der kollektive Pitch immer von null Grad beginnen. Man müsste die Aktoatromodelle in den ersten Sekunden umgehen.)

% Eingaben für die IPC-Regler
IPC_K_P    = 0.354; % 0.861401; %0;  %0.72181*0.5;                                                              % 1.194213 0.524277
IPC_K_I    = 1.194213;  
IPC_K_D    =  0; 
IPC_Switch = 'variabel';                                                         % 'on', 'off', oder 'variabel' 
IPC_ControllerType = "PI";                                                      % P, I, PI oder PID

% Eingaben für die TEF-Regler
TEF_K_P    = 0.631; %0.524277;    % 0.70622; %
TEF_K_I    = 0; %0.360148; 
TEF_K_D    = 0; %0.0360148;   
TEF_Switch = 'variabel';                                                      % 'on', 'off', oder 'variabel' 
TEF_ControllerType = "P"; 

%               - - - Auswaehlen der Winddaten - - - 
MeanWindspeed = 16; %[16:2:24,25];                                          % Mittlere Windgeschwindigkeit als Integer zugehörig zu den Winddateien angeben

windfilesAll = fullfile("WindData","Eigene_Wind_Dateien");                   % Nicht ändern!
PfadA = "TurbKlasseA";
PfadA1 = "TurbKlasseAnewSeed";
% PfadB = "";
PfadC = "ohneTurbulenz";

WindfilePfadA = fullfile(windfilesAll,PfadA);
WindfilePfadA1 = fullfile(windfilesAll,PfadA1); % Nicht ändern!
WindfilePfadB = windfilesAll; % Nicht ändern!
WindfilePfadC = fullfile(windfilesAll,PfadC); % Nicht ändern!

WindfileTest = WindfilePfadA1;                                                % Test case Pfad

% Windfiles mit Turbulenz Klasse B
windTC = [4:2:10,11:14,16:2:24,25];
lenTC = length(windTC);
for idx = 1: lenTC
    Loc_bts_files(idx)= fullfile(WindfilePfadB, sprintf("%dmps.bts",windTC(idx))); %#ok<SAGROW>
end
Loc_bts_files(lenTC+1) = fullfile("WindData","Wind_12mps","90m_12mps_twr.bts");
Loc_bts_files(lenTC+2)= fullfile(WindfilePfadB, "10mpsV2.bts");

% Windfiles ohne Turbulenz
for idx = 1: lenTC 
    Loc_bts_files(idx+lenTC+2)= fullfile(WindfilePfadC, sprintf("%dmps.bts",windTC(idx))); 
end

% Windfiles mit Turbulenz Klasse A
for idx = 1: lenTC
    Loc_bts_files(idx+2*lenTC+2)= fullfile(WindfilePfadA, sprintf("%dmps.bts",windTC(idx))); 
end
Loc_bts_files(3*lenTC+3)= fullfile(WindfilePfadA, "18mpsNewSeed.bts");

% Windfiles mit Turbulenz Klasse A mit anderem Seed
for idx = 1: lenTC
    Loc_bts_files(idx+3*lenTC+3)= fullfile(WindfilePfadA1, sprintf("%dmps.bts",windTC(idx))); 
end

for idx = 1: length(MeanWindspeed)
Loc_bts_file(idx)  = strrep(strrep(Loc_bts_files(1),WindfilePfadB,WindfileTest),...  % Replace wind turbulence type
    '4',num2str(MeanWindspeed(idx)));                                                %#ok<SAGROW> % Replace wind speed
end

if ~any(contains(Loc_bts_file, Loc_bts_files))
    error("Winddatei existiert nicht");  % Check if wind speed bts file exists
end

%        - - - Ab hier keine Benutzereingaben mehr vornehmen - - - 
%/////////////////////////////////////////////////////////////////////////%
%=========================================================================%

%% Stucture aus Eingaben erstellen
UserInputs.Job.Definition      = JobDefinition;

UserInputs.InputFileNames.Simulink   = Simulink_FileName;
UserInputs.InputFileNames.FAST       = FAST_FileName;
UserInputs.InputFileNames.MCrunch    = MCrunch_InputFileName;
UserInputs.InputFileNames.InflowWind = InflowWind_InputFileName;
UserInputs.WindDataFiles             = Loc_bts_file;
UserInputs.MeanWindspeed             = MeanWindspeed;

UserInputs.ActionCommands.MCrunch             = DoMCrunchAnalyse;
UserInputs.ActionCommands.MCrunchAnayseFolder = SimulationResultsFolderPath;
UserInputs.ActionCommands.Simulations         = DoSimulations;

UserInputs.FurtherPostProcessing.PSDanalyse.Do           = DoPSDanalyse;
UserInputs.FurtherPostProcessing.PSDanalyse.BaselineCase = BaselineCase;
UserInputs.FurtherPostProcessing.PSDanalyse.SimulationResultsFolderPath = SimulationResultsFolderPath;

UserInputs.FurtherPostProcessing.StatsAnalyse.Do           = DoStatsAnalyse;
UserInputs.FurtherPostProcessing.StatsAnalyse.BaselineCase = BaselineCase;
UserInputs.FurtherPostProcessing.StatsAnalyse.SimulationResultsFolderPath = SimulationResultsFolderPath;
UserInputs.FurtherPostProcessing.StatsAnalyse.StatsChannelName = StatsChannel;

UserInputs.FurtherPostProcessing.DELanalyse.Do           = DoDELanalyse;
UserInputs.FurtherPostProcessing.DELanalyse.BaselineCase = BaselineCase;
UserInputs.FurtherPostProcessing.DELanalyse.SimulationResultsFolderPath = SimulationResultsFolderPath;
UserInputs.FurtherPostProcessing.DELanalyse.Channels     = Channelgruppe;

UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do                          = DoActuatorPowerAnalyse;
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.BaselineCase                = BaselineCase;
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.SimulationResultsFolderPath = SimulationResultsFolderPath;

UserInputs.FurtherPostProcessing.PowerAnalyse.Do                          = DoPowerAnalyse;
UserInputs.FurtherPostProcessing.PowerAnalyse.BaselineCase                = BaselineCase;
UserInputs.FurtherPostProcessing.PowerAnalyse.SimulationResultsFolderPath = SimulationResultsFolderPath;

UserInputs.CostFunktion.Do       = DoCostAnalyse;
UserInputs.CostFunktion.Testcase = Testcase;

 
UserInputs.GenTq_Controller.Switch = GenTq_Switch;

if strcmp(CPC_Switch,"off") %CPC_Switch == "off"
    IPC_Switch = 'off';
end
UserInputs.CPC_Controller.Switch            = CPC_Switch;
UserInputs.CPC_Controller.InitialPitchAngle = CP_Initial_Pitch_Angle;

UserInputs.IPC_Controller.K_P    = IPC_K_P;
UserInputs.IPC_Controller.K_I    = IPC_K_I;
UserInputs.IPC_Controller.K_D    = IPC_K_D;
UserInputs.IPC_Controller.Switch = IPC_Switch;
UserInputs.IPC_Controller.Typ    = IPC_ControllerType;

UserInputs.TEF_Controller.K_P    = TEF_K_P;
UserInputs.TEF_Controller.K_I    = TEF_K_I;
UserInputs.TEF_Controller.K_D    = TEF_K_D;
UserInputs.TEF_Controller.Switch = TEF_Switch;
UserInputs.TEF_Controller.Typ    = TEF_ControllerType;
UserInputs.TEF.TEF_OLvalue       = 0;

UserInputs.SimTime          = Simulationzeit; 
UserInputs.StartDatalogging = floor(StartzeitDatalogging);

% Optimierung
UserInputs.Optimization.Do                             = "false";
UserInputs.Optimization.BaselineCaseFolderPath         = [];
UserInputs.Optimization.Testcase                       = OptimizationTestcase;
UserInputs.Optimization.Function                       = OptimizationFunction;
UserInputs.Optimization.StopCriteria                   = OptimizationStopCriteria;
UserInputs.Optimization.NumberIterations               = MaxIterations;
UserInputs.Optimization.NumberFunctionEvaluations      = MaxFunctionEvaluations;
UserInputs.Optimization.fmincon.Constraints.UpperBound = fminconUpperBound;
UserInputs.Optimization.fmincon.Constraints.LowerBound = fminconLowerBound;
UserInputs.Optimization.fmincon.DiffMaxChange          = DiffMaxChange; 
UserInputs.Optimization.fmincon.DiffMinChange          = DiffMinChange;
UserInputs.Optimization.fmincon.UseNonlcon             = UseNonlcon;
UserInputs.Optimization.fmincon.Nebenbedingung         = Nebenbedingung;

% Grid Search
UserInputs.GridSearch.IPC_KI_GridUpperBound = IPC_KI_GridUpperBound;
UserInputs.GridSearch.IPC_KI_GridLowerBound = IPC_KI_GridLowerBound;
UserInputs.GridSearch.IPC_KI_GridStep       = IPC_KI_GridStep;
UserInputs.GridSearch.TEF_KP_GridUpperBound = TEF_KP_GridUpperBound;
UserInputs.GridSearch.TEF_KP_GridLowerBound = TEF_KP_GridLowerBound;
UserInputs.GridSearch.TEF_KP_GridStep       = TEF_KP_GridStep;
UserInputs.GridSearch.MakeUnsymetricGrid    = MakeUnsymetricGrid;
UserInputs.GridSearch.TEF_KP_ExpandLowerBoundto = TEF_KP_ExpandLowerBoundto;
UserInputs.GridSearch.IPC_KI_ExpandLowerBoundto = IPC_KI_ExpandLowerBoundto;  

% Überprüfen, ob das Programm aus dem richtigen Ordner gestartet wurde
[~,name,~] = fileparts(pwd);
if name ~= "Main"
    fprintf('Fehler! Das Programm wurde aus dem falschen Ordner gestartet. Wechseln Sie den aktuellen MATLAB-Ornder auf den "Main"-Ordner.\n');
    return;
end

% Aufrufen der JobControl-Funktion
addpath('funktionen');
JobControl(UserInputs);


%% Unused Code
% % 0.000354 0.658919 0.000061 0.631052 -0.000259 0.00107
% % Eingaben für die IPC-Regler
% IPC_K_P    =  0.000354 *1000; %1.194213;  %0.000354;                                                               % 1.194213 0.524277
% IPC_K_I    = 1.194213; %0.658919;  
% IPC_K_D    = 0.000061; 
% IPC_Switch = 'variabel';                                                         % 'on', 'off', oder 'variabel' 
% IPC_ControllerType = "PID";                                                      % P, I, PI oder PID
% 
% % Eingaben für die TEF-Regler
% TEF_K_P    = 0.631052;   
% TEF_K_I    = 0.000259; 
% TEF_K_D    = 0.00107;   
% TEF_Switch = 'variabel' ;                                                      % 'on', 'off', oder 'variabel' 
% TEF_ControllerType = "PID"; 

% % 0.000354 0.658919 0.000061 0.631052 -0.000259 0.00107
% % Eingaben für die IPC-Regler
% IPC_K_P    =  0.000354 *1000; %1.194213;  %0.000354;                                                               % 1.194213 0.524277
% IPC_K_I    = 1.194213; %0.658919;  
% IPC_K_D    = 0.000061; 
% IPC_Switch = 'variabel';                                                         % 'on', 'off', oder 'variabel' 
% IPC_ControllerType = "PID";                                                      % P, I, PI oder PID

% Eingaben für die TEF-Regler
% TEF_K_P    = 0.631052;   
% TEF_K_I    = 0.000259 *1000; 
% TEF_K_D    = 0.00107;   
% TEF_Switch = 'variabel' ;                                                      % 'on', 'off', oder 'variabel' 
% TEF_ControllerType = "PID"; 
% 
% % 0.691554 0.631406 0 0.364612 0.265887
% IPC_K_P    =  0.691554; %1.194213;  %0.000354;                                                               % 1.194213 0.524277
% IPC_K_I    = 0.631406; %0.658919;  
% IPC_K_D    = 0.000061; 
% IPC_Switch = 'variabel';                                                         % 'on', 'off', oder 'variabel' 
% IPC_ControllerType = "PID";                                                      % P, I, PI oder PIDLoc_bts_files(
% 
% % Eingaben für die TEF-Regler
% TEF_K_P    = 0.364612;   
% TEF_K_I    = 0.265887; 
% TEF_K_D    = 0.00107;   
% TEF_Switch = 'variabel' ;                                                      % 'on', 'off', oder 'variabel' 
% TEF_ControllerType = "PID"; 

% 1.5625e-05    0.72181      0.000125    0.70622    1.5625e-05      9.375e-05
% 0.8614     0.8826     0.08614    0.36915


