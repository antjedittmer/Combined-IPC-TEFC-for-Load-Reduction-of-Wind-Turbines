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
JobDefinition        = 'Analyses';                                          % 'Analyses' oder 'Optimization' oder 'createWindPlots' 'GridSearch'


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
DiffMaxChange = 0.01;         % Maximum change in variables for finite-difference gradients (a positive scalar).
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
    StatsChannel(1) = "RootMyc1";
    StatsChannel(2) = "TwrBsMyt";
DoDELanalyse   = 'Yes';                                                      % 'Yes' oder 'No'
   % Channelgruppe(1).Gruppe = ["RootMyb1" "RootMyb2" "RootMyb3"];
    Channelgruppe(1).Gruppe = ["RootMyc1"];
    Channelgruppe(2).Gruppe = ["RootMyc2"];
    Channelgruppe(3).Gruppe = ["RootMyc3"];
        
   % Channelgruppe(4).Gruppe = ["RootMyc1" "RootMyc2" "RootMyc3"];
    Channelgruppe(4).Gruppe = ["TwrBsMyt"];
    Channelgruppe(5).Gruppe = ["TwrBsMxt"];
    Channelgruppe(6).Gruppe = ["TwrBsMzt"];    
    Channelgruppe(7).Gruppe = ["YawBrMxp"];
    Channelgruppe(8).Gruppe = ["YawBrMyp"];
    Channelgruppe(9).Gruppe = ["YawBrMzp"];    

    
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
IPC_K_P    = 0 ; 
IPC_K_I    = 1  ;  
IPC_K_D    = 0 ; 
IPC_Switch = 'variabel';                                                         % 'on', 'off', oder 'variabel' 
IPC_ControllerType = "I";                                                      % P, I, PI oder PID

% Eingaben für die TEF-Regler
TEF_K_P    = 1 ;   
TEF_K_I    = 0 ; 
TEF_K_D    = 0 ;   
TEF_Switch = 'variabel' ;                                                         % 'on', 'off', oder 'variabel' 
TEF_ControllerType = "P";                                                      % P, I, PI oder PID

%               - - - Auswaehlen der Winddaten - - - 
% Windfiles mit Turbolenz Klasse B
WindfilePfad = "WindData\Eigene_Wind_Datein\"; % Nicht ändern!
Loc_bts_file_1 = strcat(WindfilePfad, "4mps.bts");
Loc_bts_file_2 = strcat(WindfilePfad, "6mps.bts");
Loc_bts_file_3 = strcat(WindfilePfad, "8mps.bts");
Loc_bts_file_4 = strcat(WindfilePfad, "10mps.bts");
Loc_bts_file_5 = strcat(WindfilePfad, "11mps.bts");
Loc_bts_file_6 = strcat(WindfilePfad, "12mps.bts");
Loc_bts_file_7 = strcat(WindfilePfad, "13mps.bts");
Loc_bts_file_8 = strcat(WindfilePfad, "14mps.bts");
Loc_bts_file_9 = strcat(WindfilePfad, "16mps.bts");
Loc_bts_file_10 = strcat(WindfilePfad, "18mps.bts");
Loc_bts_file_11 = strcat(WindfilePfad, "20mps.bts");
Loc_bts_file_12 = strcat(WindfilePfad, "22mps.bts");
Loc_bts_file_13 = strcat(WindfilePfad, "24mps.bts");
Loc_bts_file_14 = strcat(WindfilePfad, "25mps.bts");
Loc_bts_file_15 = strcat("WindData\Wind_12mps\", "90m_12mps_twr.bts");
Loc_bts_file_16 = strcat(WindfilePfad, "10mpsV2.bts");


% Windfiles mit Turbolenz Klasse A
WindfilePfad = "WindData\Eigene_Wind_Datein\TurbKlasseA\"; % Nicht ändern!
Loc_bts_file_31 = strcat(WindfilePfad, "4mps.bts");
Loc_bts_file_32 = strcat(WindfilePfad, "6mps.bts");
Loc_bts_file_33 = strcat(WindfilePfad, "8mps.bts");
Loc_bts_file_34 = strcat(WindfilePfad, "10mps.bts");
Loc_bts_file_35 = strcat(WindfilePfad, "11mps.bts");
Loc_bts_file_36 = strcat(WindfilePfad, "12mps.bts");
Loc_bts_file_37 = strcat(WindfilePfad, "13mps.bts");
Loc_bts_file_38 = strcat(WindfilePfad, "14mps.bts");
Loc_bts_file_39 = strcat(WindfilePfad, "16mps.bts");
Loc_bts_file_40 = strcat(WindfilePfad, "18mps.bts");
Loc_bts_file_41 = strcat(WindfilePfad, "20mps.bts");
Loc_bts_file_42 = strcat(WindfilePfad, "22mps.bts");
Loc_bts_file_43 = strcat(WindfilePfad, "24mps.bts");
Loc_bts_file_44 = strcat(WindfilePfad, "25mps.bts");

Loc_bts_file_45 = strcat(WindfilePfad, "18mpsNewSeed.bts");

% Windfiles mit Turbolenz Klasse A mit anderem Seed
WindfilePfad = "WindData\Eigene_Wind_Datein\TurbKlasseAnewSeed\"; % Nicht ändern!
Loc_bts_file_46 = strcat(WindfilePfad, "4mps.bts");
Loc_bts_file_47 = strcat(WindfilePfad, "6mps.bts");
Loc_bts_file_48 = strcat(WindfilePfad, "8mps.bts");
Loc_bts_file_49 = strcat(WindfilePfad, "10mps.bts");
Loc_bts_file_50 = strcat(WindfilePfad, "11mps.bts");
Loc_bts_file_51 = strcat(WindfilePfad, "12mps.bts");
Loc_bts_file_52 = strcat(WindfilePfad, "13mps.bts");
Loc_bts_file_53 = strcat(WindfilePfad, "14mps.bts");
Loc_bts_file_54 = strcat(WindfilePfad, "16mps.bts");
Loc_bts_file_55 = strcat(WindfilePfad, "18mps.bts");
Loc_bts_file_56 = strcat(WindfilePfad, "20mps.bts");
Loc_bts_file_57 = strcat(WindfilePfad, "22mps.bts");
Loc_bts_file_58 = strcat(WindfilePfad, "24mps.bts");
Loc_bts_file_59 = strcat(WindfilePfad, "25mps.bts");

% Windfiles ohne Turbolenz
WindfilePfad = "WindData\Eigene_Wind_Datein\ohneTurbolenz\"; % Nicht ändern!
Loc_bts_file_17 = strcat(WindfilePfad, "4mps.bts");
Loc_bts_file_18 = strcat(WindfilePfad, "6mps.bts");
Loc_bts_file_19 = strcat(WindfilePfad, "8mps.bts");
Loc_bts_file_20 = strcat(WindfilePfad, "10mps.bts");
Loc_bts_file_21 = strcat(WindfilePfad, "11mps.bts");
Loc_bts_file_22 = strcat(WindfilePfad, "12mps.bts");
Loc_bts_file_23 = strcat(WindfilePfad, "13mps.bts");
Loc_bts_file_24 = strcat(WindfilePfad, "14mps.bts");
Loc_bts_file_25 = strcat(WindfilePfad, "16mps.bts");
Loc_bts_file_26 = strcat(WindfilePfad, "18mps.bts");
Loc_bts_file_27 = strcat(WindfilePfad, "20mps.bts");
Loc_bts_file_28 = strcat(WindfilePfad, "22mps.bts");
Loc_bts_file_29 = strcat(WindfilePfad, "24mps.bts");
Loc_bts_file_30 = strcat(WindfilePfad, "25mps.bts");

MeanWindspeed = 20;                                                         % Mittlere Windgeschwindigkeit als Integer zugehörig zu den Winddateien angeben
Loc_bts_file  = strrep(Loc_bts_file_54,'16',num2str(MeanWindspeed));

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

if CPC_Switch == "off"
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
UserInputs.TEF.TEF_OLvalue = 0;

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

UserInputs.GridSearch.MakeUnsymetricGrid = "No";

% Überprüfen, ob das Programm aus dem richtigen Ordner gestartet wurde
[~,name,~] = fileparts(pwd);
if name ~= "Main"
    fprintf('Fehler! Das Programm wurde aus dem falschen Ordner gestartet. Wechseln Sie den aktuellen MATLAB-Ornder auf den "Main"-Ordner.\n');
    return;
end

% Aufrufen der JobControl-Funktion
addpath('funktionen');
GridSearch(UserInputs);


