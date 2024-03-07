% function [pks, locs , closestIndex] = test(PSD_Data)        
%         for x = 1 : 3
%             if x == 1
%                 p = 0.2;
%             end
%             if x == 2
%                 p = 0.4;
%             end
%             if x == 3
%                 p = 0.6;
%             end
%             
%             % finde alle lokalen Maxima und Minima
%             localmax = islocalmax(PSD_Data(:, 2));
%             localmin = islocalmin(PSD_Data(:, 2));
%             
%             % finde die Indexe an dennen die Extrema vorkommen
%             [~,LocbMax] = ismember(localmax,PSD_Data(:, 2));
%             [~,LocbMin] = ismember(localmin,PSD_Data(:, 2));
%             
%             
%             k = find(LocbMax);
%             j = find(LocbMin);
%             
%             % Frequenzen an dennen die Extrema vorkommen
%             F_max = PSD_Data(LocbMax(k), 2);
%             F_min = PSD_Data(LocbMin(j), 2);
%             
%             
%             [~,closestIndexMax] = min(abs(F_max-p));
%             [~,closestIndexMin] = min(abs(F_min-p));
%             
%             % Frequenzen der Maxima die am nächsten an P sind
%             F_max_closest = F_max(closestIndexMax);
%             F_min_closest = F_min(closestIndexMin);
%             
%             F_closest = min(abs([F_max_closest F_min_closest] -p));
%             
%             [~,closestIndex] = ismember(F_closest,PSD_Data(:, 1));
%             
% 
%             
% %             pks(x)  = PSD_Data(closestIndex, 2);
% %             locs(x) = PSD_Data(closestIndex, 1); 
%             
%             pks(x)  =1;
%             locs(x) = 1;
%         end
% end
clear all
SimRunFolderPath = 'C:\Users\oster\Desktop\MA Repo\11.02.23\openFAST-Tool-Masterarbeit-master (2)\openFAST-Tool-Masterarbeit-master\Main\Post_processing\Simulation_Run_at_12-Feb-23_15-09-07';
% z = 4;
% BaselineCase = "5MW_Land.SFunc_TEF_off_IPC_off";
% DoOptimization = 'false';
% readBaselineData = 'false';

% Data = LoadPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
BaselineCaseFolderPath = 'C:\Users\oster\Desktop\MA Repo\11.02.23\openFAST-Tool-Masterarbeit-master (2)\openFAST-Tool-Masterarbeit-master\Main\Post_processing\Simulation_Run_at_12-Feb-23_15-07-46';
% DoOptimization = 'true';
% Simulationzeit           = 60;
% StartzeitDatalogging     = 0.1*Simulationzeit;
% UserInputs.StartDatalogging = floor(StartzeitDatalogging);
% 
% [PowerReferenceAnalyseOut] = PowerReferenceAnalyse(SimRunFolderPath, BaselineCase, BaselineCaseFolderPath, DoOptimization, UserInputs);




% clear all
% SimRunFolderPath = 'C:\Users\oster\Desktop\MA Repo\11.02.23\openFAST-Tool-Masterarbeit-master (2)\openFAST-Tool-Masterarbeit-master\Main\Post_processing\Simulation_Run_at_11-Feb-23_16-35-38';
% z = 4;
BaselineCase = "5MW_Land.SFunc_TEF_off_IPC_off";
DoOptimization = 'true';
readBaselineData = 'false';
% BaselineCaseFolderPath = 'C:\Users\oster\Desktop\MA Repo\11.02.23\openFAST-Tool-Masterarbeit-master (2)\openFAST-Tool-Masterarbeit-master\Main\Post_processing\Simulation_Run_at_11-Feb-23_16-33-05';
%  
% % Data = LoadActuatorPowerData(SimRunFolderPath, z, BaselineCase, DoOptimization, readBaselineData);
% 
Simulationzeit           = 60;
StartzeitDatalogging     = 0.1*Simulationzeit;
UserInputs.StartDatalogging = floor(StartzeitDatalogging);


[ActuatorPowerAnalyseOut] = ActuatorPowerAnalyse(SimRunFolderPath, BaselineCase, BaselineCaseFolderPath, DoOptimization, UserInputs);
