function [] = LoadDataForCPC(SimConfig)
%LOADDATAFORCPC Summary of this function goes here
%   Detailed explanation goes here

% Laden der Workspacevariablen für den Basis-Controller
load('CP_Controll_WS.mat');

Control.DT = 0.01;     % Der Wert für Control.DT muss dem Wert für DT aus der fst-Datei entsprechen

assignin('base','CertificationSettings', CertificationSettings);
assignin('base','Control', Control);
assignin('base','Drivetrain', Drivetrain);
%assignin('base','DT', DT);
P_InitAngle = SimConfig.controller.CPC.InitialPitchAngle;
assignin('base','P_InitAngle', P_InitAngle);
assignin('base','RPM_Init', RPM_Init);
assignin('base','T_GenSpeedInit', T_GenSpeedInit);

end

