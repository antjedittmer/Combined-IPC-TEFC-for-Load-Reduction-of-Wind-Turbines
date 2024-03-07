function nF = plotPaper06_TEFOL_2(nF,dirBLData0,dirBLDataNeg10, dirBLDataPos10)

if ~nargin
    close all;
    nF = 1;
end

if nargin < 2
    dirBLData0 = 'Simulation_Run_at_18-Dec-23_23*';
    dirBLDataNeg10 = 'Simulation_Run_at_19-Dec-23_19*';
    dirBLDataPos10 = 'Simulation_Run_at_19-Dec-23_2*';
end

dirDataOL = 'DataOL';
if ~isfolder(dirDataOL)
    mkdir(dirDataOL);
end
BLMat = fullfile(dirDataOL,'BL.mat');
TEFneg10Mat = fullfile(dirDataOL,'TEFneg10.mat');
TEFpos10Mat = fullfile(dirDataOL,'TEFpos10.mat');

dirFig = 'fig2';
if ~isfolder(dirFig)
    mkdir(dirFig);
end
set(0,'defaultLineLineWidth',1)
MeanWindspeedVec = [4:2:10,11:14,16:2:24,25];
nameCell = {'GenPwr','RotSpeed','BldPitch1','RtAeroFxh'}; %'RootFxb1','RootFyb1',

if exist(BLMat,'file') == 2
    load(BLMat,'BL');
else
    BL = assignFromData(dirBLData0, nameCell,MeanWindspeedVec);
    save(BLMat,'BL');
end

if exist(TEFneg10Mat,'file') == 2
    load(TEFneg10Mat,'TEFneg10');
else
    TEFneg10 = assignFromData(dirBLDataNeg10, nameCell,MeanWindspeedVec);
    save(TEFneg10Mat,'TEFneg10');
end

if exist(TEFpos10Mat,'file') == 2
    load(TEFpos10Mat,'TEFpos10');
else
    TEFpos10 = assignFromData(dirBLDataPos10, nameCell,MeanWindspeedVec);
    save(TEFpos10Mat,'TEFpos10');
end

ylCell = {'$P_{gen}$, MW','$n_{rot}$, rpm','$T_{rot}$, kN', '$\beta_{0}$, $^{\circ}$'};
yCell = strrep(ylCell,'$','');
yCell = strrep(yCell,'^{\circ}','deg');

nameCell = {'GenPwr','RotSpeed','RtAeroFxh','BldPitch1'};
len = length(ylCell);
hs = nan(len,1);
wind = MeanWindspeedVec;
fs = 12.5;
ms = 5;
lw = 1;
nV = [1000,1,1,1];


cl = lines;
clSwitch = 1;

for idx = 1:len

    idxFig  = nF + ceil(idx/2);
    idxAx = 2 - mod(idx,2);

    if idxAx == 1
        nf = figure(idxFig);
        nfpos = nf.Position;
        nf.Position= [nfpos(1:2),  nfpos(3) nfpos(4) *0.7];
        tiledlayout(2,1,'TileSpacing','Compact','Padding','Compact');

    end
    nexttile
    hs(idxAx) = gca;
    % hs(idxAx) = subplot(len/2,1,idxAx);
    x0 = BL.(nameCell{idx})/nV(idx);
    x1 = TEFneg10.(nameCell{idx})/nV(idx);
    x2 = TEFpos10.(nameCell{idx})/nV(idx);
    if clSwitch == 1
        plot(wind,x0,'ro-','Linewidth',lw,'MarkerSize',ms); hold on;
        plot(wind,x1,'bs-.','Linewidth',lw,'MarkerSize',ms);
        plot(wind,x2,'bd--','Linewidth',lw,'MarkerSize',ms,'Color',[0 0.6 0]);
    else
        plot(wind,x0,'ko-','Linewidth',lw,'MarkerSize',ms); hold on;
        plot(wind,x1,'bs-.','Linewidth',lw,'MarkerSize',ms,'Color',cl(1,:));
        plot(wind,x2,'bd--','Linewidth',lw,'MarkerSize',ms,'Color',cl(end,:));
    end

    %ylabel(ylCell{idx},'interpreter','latex');
    if idxAx == 1
        if clSwitch == 1
            titleStr = ['Open Loop TEF: \color{blue}\eta_{ref} = -10^{\circ} ',...
                '\color{red}\eta_{ref} = 0^{\circ} \color[rgb]{0,0.5,0}\eta_{ref} = 10^{\circ}'];
        else
            titleStr = ['Open Loop TEF: \color[rgb]{0    0.4470    0.7410}\eta_{ref} = -10^{\circ} ',...
                '\color{black}\eta_{ref} = 0^{\circ} \color[rgb]{ 0.4940, 0.1840,0.5560}\eta_{ref} = 10^{\circ}'];
        end
        title(titleStr)
        % Create textbox
        annotation(nf,'textbox',...
            [0.144 0.793 0.257 0.038],...
            'String',{'Region II'},...
            'LineStyle','none',...
            'FontSize',13,...
            'FitBoxToText','off');

        if idx < 2
            yA = 0.793; %0.813;
            xA = 0.448;
        else
            yA =  0.793;
            xA = 0.483;
        end

        % Create textbox
        annotation(nf,'textbox',...
            [xA yA 0.207 0.038],...
            'String',{'Region III'},...
            'LineStyle','none',...
            'FontSize',13,...
            'FitBoxToText','off');

    end
    ylabel(yCell{idx});
    xlim([wind(1),wind(end)])
    minX = min(min([x0,x1,x2]));
    maxX = max(max([x0,x1,x2]));
    deltaX = (maxX- minX)*0.1;
    xlim([wind(1),wind(end)]);
    ylim([minX, maxX + deltaX]);
    X = [wind(1), 11.4, 11.4,wind(1)];
    Y = [minX,minX, maxX + deltaX,  maxX + deltaX];
    fill(X,Y,'k','FaceAlpha',0.1,'LineStyle','none');
    hold off;
    grid on; % axis tight;


    if idxAx == 2
        xlabel('Wind speed, m/s');
    end

    set(hs(idxAx),'FontSize',fs,'xtick',MeanWindspeedVec,...
        'XTickLabelRotation',45); % 'TickLabelInterpreter','Latex',
    set(hs(idxAx),'XTickLabelRotation',45);


    % set(hs(idx),'LineWidth',1)

filenamepng = ['fig06_TEFOL_',num2str(idxFig-nF)];

filepathpng = fullfile(dirFig,filenamepng);

print(gcf,filepathpng, '-dpng');
print(gcf,filepathpng, '-depsc');

end




function BL = assignFromData(dirBLData, nameCell,MeanWindspeedVec)

mainFolder = fileparts(fileparts(mfilename('fullpath')));
dirBL = dir(fullfile(mainFolder,'Post_processing',dirBLData));

for idx = 1: length(nameCell)
    BL.(nameCell{idx}) = nan(length(MeanWindspeedVec),1);
end

for idx =1: length(MeanWindspeedVec )

    dirname = sprintf('Results_%dmps', MeanWindspeedVec(idx));
    aDir = fullfile(dirBL(1).folder,dirBL(idx).name,dirname);

    load(fullfile(aDir,'OutList.mat'), 'OutList');

    tmp = load(fullfile(aDir,'OutData_TEF_off_IPC_off.mat'), 'OutData');

    tmpTable = array2table(tmp.OutData,'VariableNames',OutList);

    time = tmpTable.Time >= 60;

    for idx1 = 1: length(nameCell)
        BL.(nameCell{idx1}) (idx) = mean(tmpTable.(nameCell{idx1})(time));
    end
end