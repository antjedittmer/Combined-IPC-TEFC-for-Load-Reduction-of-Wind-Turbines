clc; close all; clc;

windTC = [16:2:24,25];
MainFolder = fileparts(pwd);
SimDir = 'aWindSweepTurbA_16_25';
PostprocessingFolder = fullfile(MainFolder,'Post_processing_for_plots',SimDir);

lenTC = length(windTC);
evalObjDEL = nan(lenTC,7);
evalObjSum = nan(lenTC,6);
for idx = 1 : lenTC
    WindCase = sprintf('Results_%dmps',windTC(idx));
    WindCasePath = fullfile(PostprocessingFolder,WindCase);
    % Load damage equivalent loads
    tmp = load(fullfile(WindCasePath, 'DELAnalyseResults.mat'));  % load DEL
    tmp1 = struct2array(tmp.DELAnalyseResults.(WindCase).results); %DEL in vector
    len1 = length(tmp1);
    tmp2 = reshape(tmp1,4,len1/4); %matrix with results
    tmpIPFC = tmp2(4,:);
    evalObjDEL(idx,:) = 1 + [max(tmpIPFC(1:3)), tmpIPFC(4:9)]/100; %percentage of change
    % Load actuator power
    tmpa = load(fullfile(WindCasePath, 'ActuatorPowerAnalyseOut.mat')); %load act pwr
    tmpa1 = tmpa.ActuatorPowerAnalyseOut.(WindCase).TEF_on_IPC_on(2)/100; % percentage of increase
    % Load Power
    tmpb = load(fullfile(WindCasePath, 'PowerReferenceAnalyseOut.mat')); %load act pwr
    tmpb1 = 1 + tmpb.PowerReferenceAnalyseOut.(WindCase).TEF_on_IPC_on([2,8])/100; % percentage of increase
    evalObjSum(idx,:) = [evalObjDEL(idx,1), mean(evalObjDEL(idx,2:4)), mean(evalObjDEL(idx,5:7)),...
        tmpb1',...
        tmpa1];
end

sprintf('%2.2f ', mean(evalObjSum));