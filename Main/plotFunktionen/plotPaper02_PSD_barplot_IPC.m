%clc; clear;
function plotPaper02_PSD_barplot_IPC
close all;
addpath("breakyaxis");

MainFolder = fileparts(pwd);

SimRunDir = 'SimInitCtrl_P1_I1'; %'Simulation_Run_at_13-Dec-23_16-55-14'; % orig: I = 1 (IPC), P = 1 (IFC)
%SimRunDir = 'Simulation_Run_at_14-Dec-23_11-24-11'; % opt I (IPC) P (IFC)
%SimRunDir = 'Simulation_Run_at_14-Dec-23_12-29-32'; % opt PID (IPC) PID (IFC):
%SimRunDir = 'Simulation_Run_at_14-Dec-23_13-17-41'; % opt PID (IPC) PID (IFC): mod. ADi (P Ipc = 1.1
%SimRunDir = 'Simulation_Run_at_14-Dec-23_14-08-28'; % opt PID (IPC) PID (IFC): mod. ADi
%SimRunDir = 'Simulation_Run_at_14-Dec-23_14-35-37'; % opt PID (IPC) PID (IFC): mod. ADi
%SimRunDir ='Simulation_Run_at_18-Dec-23_13-01-16';
%SimRunDir = 'Simulation_Run_at_21-Dec-23_15-33-42';
% SimRunDir = 'Simulation_Run_at_21-Dec-23_15-57-14';
% SimRunDir = 'Simulation_Run_at_28-Dec-23_10-05-29'; % opt I=P =0.7, 18
SimRunDir = 'Simulation_Run_at_20240508_1240'; % opt I=P =0. 7, 16

% SimDir = fullfile('Simulation_Run_at_05-Sep-23_23-34-28','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_13-Dec-23_16-55-14','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_14-Dec-23_11-24-11','Results_16mps'); %opt I (IPC) P (IFC)
% SimDir = fullfile('Simulation_Run_at_14-Dec-23_12-29-32','Results_16mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_16mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_25mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_18mps'); %opt PID (IPC) PID (IFC)
SimDir = fullfile(SimRunDir,'Results_16mps'); %opt PID (IPC) PID (IFC)

legendCellNew =  [{'Baseline control and '}
    {'IPC'}];

%PostprocessingFolder = fullfile(MainFolder,'Post_processing',SimDir);
PostprocessingFolder = fullfile(MainFolder,'Post_processing_for_plots',SimDir);

dirFig = 'fig2';
if ~isfolder(dirFig)
    mkdir(dirFig);
end

plotAll = 0;

figureInDir = dir(fullfile(PostprocessingFolder,'TD*.fig')); %'5MW_Land*.fig'
lenDir = length(figureInDir);

XDataCell = cell(lenDir,2);
YDataCell = cell(lenDir,2);
% XDataCellE = cell(lenDir,1);
% YDataCellE = cell(lenDir,1);

legendCell = cell(lenDir,1);
strIFC = 'TEFC'; %'IFC';
no = lenDir+1;

for idxF = 1: 2 %length(figureInDir)
    
    fname = figureInDir(idxF).name;
    fig = openfig(fullfile(PostprocessingFolder, fname));
    
    dataXObjs = findobj(fig,'-property','XData'); %dataYObjs = findobj(fig,'-property','YData');
    
    XdataCell = get(dataXObjs,'Xdata'); %
    YdataCell = get(dataXObjs,'Ydata'); %
    [~, idx]  = max(cellfun('length',XdataCell)); % pick the data not the extrema
    [~, idxE]  = min(cellfun('length',XdataCell)); % pick the extrema
    
    XdataAll = XdataCell{idx};
    YdataAll = YdataCell{idx};
    
    idx1 = XdataAll <= 0.7;
    
    XDataCell{idxF,1} = XdataAll(idx1);
    YDataCell{idxF,1} = YdataAll(idx1);
    
    XDataCell{idxF,2} = XdataCell{idxE};
    YDataCell{idxF,2} = YdataCell{idxE} ;
    
    %     XDataCellE{idxF} = XdataCell{idxE};
    %     YDataCellE{idxF} = YdataCell{idxE};
    
    legTemp = strrep(strrep(fname,'5MW_Land.SFunc_',''),'.fig','');
    legTemp2 = strrep(strrep(legTemp,'_IPC',', IPC'),'_',': ');
    legTemp2 = strrep(legTemp2,'TEF',strIFC);
    legendCell{idxF} = legTemp2;
end
legendCell = legendCellNew;

if plotAll == 0
    close all;
end

% xlabelStr = 'Frequency, Hz';
% ylabelStr = 'PSD Blade root flapwise moment, kNm^2/Hz';
% cl = {'k-','b--','g-.','r--'};
% fs = 12;
% lw = 0.7;

vec1 = 1:3;
%v1 = vec1(end);
vec2 = []; %[1,4];


%% Plot 5&6: Log scale

if plotAll == 1
    type = 0;
    filenamepng = 'fig02_PSDroot_semilog';
    filepathpng = fullfile(dirFig,filenamepng);
    plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type);
    
    filenamepng = 'fig02_PSDroot_semilog_1';
    no = lenDir+2;
    filepathpng = fullfile(dirFig,filenamepng);
    plotPSD(no,vec2,XDataCell,YDataCell,legendCell,filepathpng,type);
    
    %% Plot 7&8: lin scale, zoom smaller PSD
    type = 1;
    no = lenDir+3;
    filenamepng = 'fig02_PSDroot_linear';
    filepathpng = fullfile(dirFig,filenamepng);
    plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type);
    
    filenamepng = 'fig02_PSDroot_linear_1';
    no = lenDir+4;
    filepathpng = fullfile(dirFig,filenamepng);
    plotPSD(no,vec2,XDataCell,YDataCell,legendCell,filepathpng,type);
end

%% Plot 9&10: lin scale, split y axis
addpath(genpath('breakyaxis'));
type = 2;
no = lenDir+5;
filenamepng = 'fig02_TD_PSDroot_breaky';
filepathpng = fullfile(dirFig,filenamepng);
titleStr = ['            ', legendCell{1}, ...
    '; \color{blue}' legendCell{2}];
plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type,titleStr)
return

cCell = {'black','blue'};
%Cvec = [[1,1,1];[0,0,1];[0,1,0];[1,0,0]];
v2 = vec2(end);
c = cCell{v2};

filenamepng = 'fig02_PSDroot_breaky1';
no = lenDir+6;
filepathpng = fullfile(dirFig,filenamepng);
titleStr = ['  ', legendCell{1}, ' \color{',c,'}' legendCell{v2}];
plotPSD(no,vec2,XDataCell,YDataCell,legendCell,filepathpng,type,titleStr)

filenamepng = 'fig02_PSDroot_breaky2';
vec2 = [1,2];
v2 = vec2(end);
c = cCell{v2};


if plotAll == 1
    no = lenDir+7;
    filepathpng = fullfile(dirFig,filenamepng);
    
    legendCell1 = strrep(legendCell,'TEFC: off, ','');
    titleStr1 = ['     Comparison NTW, mean wind 16 m/s: ' legendCell1{1}, '  \color{',c,'}' legendCell1{v2}];
    plotPSD(no,vec2,XDataCell,YDataCell,legendCell1,filepathpng,type,titleStr1)
end

function plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type,titleStr)

if nargin < 8
    titleStr = '';
end

xlabelStr = 'Frequency, Hz';
ylabelStr = 'PSD Blade root flapwise moment, kNm^2/Hz';
cl = {'k-','b--','g-.','r--'};
fs = 12;
lw = 0.8;

v2 = vec1(end);
%cCell = {'black','blue','green','red'};
Cvec = [[1,1,1];[0,0,1];[0,1,0];[1,0,0]];
c = Cvec(v2,:);

nf = figure(no);
nfpos = get(0,'defaultFigurePosition');
nf.Position= [nfpos(1:3), nfpos(4)*0.9];

if type == 0 % log plot
    
    for idxP = vec1
        semilogy(XDataCell{idxP,1},YDataCell{idxP,1},cl{idxP},'linewidth',lw);
        hold on;
    end
    axis tight; grid on;
    ylimOrig = get(gca,'YLim');
    set(gca,'YLim', [ylimOrig(1),1.1*ylimOrig(2)]);
    legend(legendCell(vec1),'FontSize',fs-1);
    
elseif type > 0 % lin plot
    
    for idxP =  vec1(1:2)
        plot(XDataCell{idxP,1},YDataCell{idxP,1},cl{idxP},'linewidth',lw);
        hold on;
    end
    axis tight; grid on;
    ylimOrig = get(gca,'YLim');
    
    temp = YDataCell(:,2);
    temp = temp(1:2);
    str1 = cell(2*length(temp),1);
    for idxS = 1:length(temp)
        str1{idxS} = sprintf('%2.2e', temp{idxS}(1));
        str1{idxS+length(temp)} = sprintf('%2.2e', temp{idxS}(2));
    end
    
    
    set(gca,'YLim',[ylimOrig(1),5.5*10^7])
    legend(legendCell,'FontSize',fs-1);
    
    
    % Create textarrow for BL
    annotation(gcf,'textarrow',[0.425 0.376+0.02],[0.842-0.52  0.906-0.52],...
        'String',str1(1),...
        'FontSize',12);
    annotation(gcf,'textarrow',[0.65+0.05 0.62+0.05 ],...
        [0.21 0.19],'String',str1(3),'FontSize',12);
    
    
    % Create textarrow for IPC
    annotation(gcf,'textarrow',[0.42738095238095+0.05 0.398809523809524+0.05],...
        [0.316460317460316-0.15 0.27689594356261-0.15],'Color',[0 0 1],'String',str1(2),...
        'FontSize',12);
    annotation(gcf,'textarrow',[0.65+0.05 0.62+0.05 ],...
        [0.21-0.05 0.19-0.05],'Color',[0 0 1],'String',str1(4),...
        'FontSize',12);
    
    
    xlabel(xlabelStr, 'FontSize',fs);
    ylabel(ylabelStr,'FontSize',fs);
    
    
end

print(gcf,filepathpng, '-dpng');
print(gcf,filepathpng, '-depsc');
