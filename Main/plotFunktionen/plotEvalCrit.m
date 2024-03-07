clc; clear; close all;

%% 
ws = 'Results_16mps';
MainFolder = fileparts(pwd);
SimDir = fullfile('Simulation_Run_at_28-Dec-23_10-44-58',ws);
PostprocessingFolder = fullfile(MainFolder,'Post_processing_for_plots',SimDir);

%% set file and folder names
fileDEL = fullfile(PostprocessingFolder,'DELAnalyseResults.mat');
fileActPwrIPCoff = fullfile(PostprocessingFolder,'Pitch_Actuator_Power_TEF_off_IPC_off.mat');
fileActPwrIPCon = fullfile(PostprocessingFolder,'Pitch_Actuator_Power_TEF_off_IPC_on.mat');
filePwrRef = fullfile(PostprocessingFolder,'PowerReferenceAnalyseOut.mat');

dirFig = 'figIPC';
if ~isfolder(dirFig)
    mkdir(dirFig);
end
vecEvalCell{1} = [1,3:5]; % set which parameters are to be evaluated
vecEvalCell{2} = 1:5;

%% get information for DEL and assign DEL
tmp = load(fileDEL);
tableDEL = tmp.DELAnalyseResults.(ws);
dataDel = tableDEL.DELs(:,1:2);
nameDEL = tableDEL.Gruppe;
idxRoot = contains(nameDEL,'Root');
idxTweBs = contains(nameDEL,'TwrBs');
C(1,1:2) = mean(dataDel(idxRoot,:)); % mean blade root flapwise moments
C(2,1:2) = mean(dataDel(idxTweBs,:)); % mean tower base moments

%% get information act. pwr
load(fileActPwrIPCoff,'PichActuatorPower');
ActPwrICSoff = mean(PichActuatorPower);
load(fileActPwrIPCon,'PichActuatorPower');
ActPwrICSon = mean(PichActuatorPower);
C(3,1:2) = [mean(ActPwrICSoff(2:end)), mean(ActPwrICSon(2:end))]; % power ref

%% get information Pwr mean and var
tmp = load(filePwrRef);
tablePwr = tmp.PowerReferenceAnalyseOut.(ws);
dataPwr = tablePwr{:,2:3};
namePwr = tablePwr.Properties.RowNames;
idxPwrMean = strcmp(namePwr,'Mittelwerte der elektrischen Leistung');
idxPwrStd = strcmp(namePwr,'Standardabweichung der el. Leistung');
C(4,1:2) = dataPwr(idxPwrMean,:); % mean blade root flapwise moments
C(5,1:2) = dataPwr(idxPwrStd,:); % mean tower base moments

Cnorm = C./C(:,1);
cellEvalC = ...
    {'DEL_{Bl}','DEL_{Twr}','P_{Act}','mean P_{Gen}','std P_{Gen}'};

for idx = 1: length(vecEvalCell)
    vecEvalC = vecEvalCell{idx};
    le = length(vecEvalC);
    filenamepng = ['DelCrit' num2str(le)];

    figure(idx)
    h = bar(Cnorm(vecEvalC,:));

    h(1).FaceColor = 'black';
    h(2).FaceColor = 'blue';
    grid on;
    legend('CPC','IPC')
    set(gca,'XTickLabel',cellEvalC(vecEvalC),'FontSize',13)
    ylabel('Normalized evaluation criteria')

    ylimOrig = get(gca,'YLim');
    d = 0.05*(ylimOrig(2)- ylimOrig(1));
    set(gca,'YLim',[ylimOrig(1),ylimOrig(2)+d])

    xtips1 = h(2).XEndPoints;
    ytips1 = h(2).YEndPoints;

    labels1 = regexp(sprintf('%2.2f ',h(2).YData),' ','split');
    labels1 = labels1(1:le);
    text(xtips1+0.025,ytips1,labels1,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontSize',13)

    print(gcf,fullfile(dirFig,filenamepng), '-dpng');
    print(gcf,fullfile(dirFig,filenamepng), '-depsc');

end

%% 
Cnorm(:,2) = [0.77 0.96 2.94 1.00 1.00]';
vecEvalCell{1} = [1:2,4];
vecEvalCell{2} = [1:2,4:5]; % set which parameters are to be evaluated
vecEvalCell{3} = 1:5;
locCell = {'SouthEast','SouthEast','NorthEast'};

for idx = 1: length(vecEvalCell)
    vecEvalC = vecEvalCell{idx};
    le = length(vecEvalC);
    filenamepng = ['DelCrit' num2str(le)];

    figure(idx)
    h = bar(Cnorm(vecEvalC,:));

    h(1).FaceColor = 'black';
    h(2).FaceColor = 'red';
    grid on;
    legend('Baseline','IPC + TEFC', 'Location', locCell{idx} )
    set(gca,'XTickLabel',cellEvalC(vecEvalC),'FontSize',13)
    ylabel('Normalized evaluation criteria')

    ylimOrig = get(gca,'YLim');
    d = 0.05*(ylimOrig(2)- ylimOrig(1));
    set(gca,'YLim',[ylimOrig(1),ylimOrig(2)+d])

    xtips1 = h(2).XEndPoints;
    ytips1 = h(2).YEndPoints;

    labels1 = regexp(sprintf('%2.2f ',h(2).YData),' ','split');
    labels1 = labels1(1:le);
    text(xtips1+0.025,ytips1,labels1,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontSize',13)

    print(gcf,fullfile(dirFig,[filenamepng,'IPCTECPaper']),'-dpng');
    print(gcf,fullfile(dirFig,[filenamepng,'IPCTECPaper']),'-depsc');

end


for idx = 1: length(vecEvalCell)
    vecEvalC = vecEvalCell{idx};
    le = length(vecEvalC);
    filenamepng = ['DelCrit' num2str(le)];

    figure(idx)
    h = bar(Cnorm(vecEvalC,:));

    h(1).FaceColor = 'black';
    h(2).FaceColor = 'red';
    grid on;
    legend('Baseline','IPC + TEFC')
    set(gca,'XTickLabel',cellEvalC(vecEvalC),'FontSize',13)
    ylabel('Normalized evaluation criteria')

    ylimOrig = get(gca,'YLim');
    d = 0.05*(ylimOrig(2)- ylimOrig(1));
    set(gca,'YLim',[ylimOrig(1),ylimOrig(2)+d])

    xtips1 = h(2).XEndPoints;
    ytips1 = h(2).YEndPoints;

    labels1 = regexp(sprintf('%2.2f ',h(2).YData),' ','split');
    labels1 = labels1(1:le);
    text(xtips1+0.025,ytips1,labels1,'HorizontalAlignment','center',...
        'VerticalAlignment','bottom','FontSize',13)

    print(gcf,fullfile(dirFig,[filenamepng,'IPCTECPaper']),'-dpng');
    print(gcf,fullfile(dirFig,[filenamepng,'IPCTECPaper']),'-depsc');

end
