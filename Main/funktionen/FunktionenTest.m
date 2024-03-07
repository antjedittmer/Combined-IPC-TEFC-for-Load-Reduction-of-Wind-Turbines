




% SheetName = 'NREL_5MW_TEF_off_IPC_on';
% ExcelFileName = 'Analyse_PSDs.xls';
% ArchivFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_21-Nov-22_12-12-27\Results_8mps';
% AnalysePSD(ArchivFolderPath, ExcelFileName, SheetName);

%BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_off";
%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_21-Nov-22_19-04-59'
%FurtherPostProcessing(SimRunFolderPath,BaselineCase);

%filename = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_21-Nov-22_12-12-27\Results_8mps\Analyse_PSDs.xls';
%sheets = sheetnames(filename)

%A= [ 1 ,2 ; 3 , 5; 6,7];
%SX = size(A)


% % Suchen der Stellen P1 P2 und P3  
% clear all
% 
% PSD_Data(:,1) = 0:0.01:pi;
% PSD_Data(:,2) = 3*sin(50.*PSD_Data(:,1));
% 
% %[pks, locs, closestIndex] = test(PSD_Data);
% 
% 
% for x = 1 : 3
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
%             localmax2 = PSD_Data(localmax, 2);
%             localmin2 = PSD_Data(localmin, 2);
%             
%             % finde die Indexe an dennen die Extrema vorkommen
%             [~,LocbMax] = ismember(localmax2,PSD_Data(:, 2));
%             [~,LocbMin] = ismember(localmin2,PSD_Data(:, 2));
%             
%             
%             k = find(LocbMax);
%             j = find(LocbMin);
%             
%             % Frequenzen an dennen die Extrema vorkommen
%             F_max = PSD_Data(LocbMax(k), 1);
%             F_min = PSD_Data(LocbMin(j), 1);
%             
%             
%             [~,closestIndexMax] = min(abs(F_max-p));
%             [~,closestIndexMin] = min(abs(F_min-p));
%             
%             % Frequenzen der Maxima die am nächsten an P sind
%             F_max_closest = F_max(closestIndexMax);
%             F_min_closest = F_min(closestIndexMin);
%             
%             [~,F_closest_idx] = min([abs(F_max_closest-p) abs(F_min_closest-p)]);
%             
%             if F_closest_idx == 1
%                 F_closest = F_max_closest;
%             elseif F_closest_idx == 2
%                 F_closest = F_min_closest;
%             end
%             
%             [~,closestIndex] = ismember(F_closest,PSD_Data(:, 1));
%                        
%             pks(x)  = PSD_Data(closestIndex, 2);
%             locs(x) = PSD_Data(closestIndex, 1); 
%             
%         end
% 
% %% Plotten der Leistungsdichtesprktren
% figure 
% plot(PSD_Data(:, 1), PSD_Data(:, 2),'-*',...
%          locs, pks, 'r-*');
% grid on
% xlim([0 1]);
% title('Leistungsdichtespektrum');
% xlabel('Frequenz [Hz]');

% clear all
% 
% BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_off";
% SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_27-Nov-22_11-52-19'
% 
% outStats = AnalyseStats(SimRunFolderPath, BaselineCase);

              
%BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_on";
%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_25-Nov-22_17-48-32'

% Channelgruppen(1).Gruppe = ["RootMyb1" "RootMyb2" "RootMyb3"];
% Channelgruppen(2).Gruppe = ["x" "y"];
% 
% length(Channelgruppen(1).Gruppe);
% 
% [outDEL] = AnalyseDEL(SimRunFolderPath,BaselineCase,Channelgruppen);


              
%BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_on";
%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_25-Nov-22_17-48-32'

% [outPSD] = AnalysePSD(SimRunFolderPath,BaselineCase);
% 
% 
% Testcase = "NREL_5MW.SFunc_TEF_on_IPC_on";
% [CostsOut] = CostFunction1(outPSD,outStats,outDEL,Testcase)

clear all

%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_26-Nov-22_14-29-34'

%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_28-Nov-22_12-06-19'

% BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_off";
% Optimization = 'true';
% readBaselineData = 'false';
% idx = 3;
% [Data,BaselineIndex] = readDataStats(SimRunFolderPath, idx, BaselineCase, Optimization, readBaselineData);

%SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_28-Nov-22_13-59-21';
SimRun = 'Simulation_Run_at_05-Sep-23_23-34-28';
Baseline = 'Simulation_Run_at_07-Sep-23_14-53-53';

MainFolder = fileparts(pwd);
PostprocessingFolder = fullfile(MainFolder,'Post_processing');

% SimRunFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_26-Nov-22_14-29-34';
SimRunFolderPath = fullfile(PostprocessingFolder,SimRun); %'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_26-Nov-22_14-29-34';
% BaselineCaseFolderPath = 'C:\Users\oster\Desktop\Desktop_MA\Main\Post_processing\Simulation_Run_at_28-Nov-22_12-06-19';
BaselineCaseFolderPath = fullfile(PostprocessingFolder,Baseline);

BaselineCase = "NREL_5MW.SFunc_TEF_off_IPC_off";

DoOptimization = "false";
Channelgruppen(1).Gruppe = ["RootMyb1" "RootMyb2" "RootMyb3"];
Channelgruppen(2).Gruppe = ["x" "y"];

% [AnalyseDELout] = AnalyseDEL_2(SimRunFolderPath,BaselineCase,Channelgruppen,BaselineCaseFolderPath,DoOptimization)
%AnalyseDELout = AnalyseDEL_2_max(SimRunFolderPath,BaselineCase,Channelgruppen,BaselineCaseFolderPath,DoOptimization)
AnalyseDELout = AnalyseDEL_2_max(SimRunFolderPath,BaselineCase,Channelgruppen,BaselineCaseFolderPath,DoOptimization)
