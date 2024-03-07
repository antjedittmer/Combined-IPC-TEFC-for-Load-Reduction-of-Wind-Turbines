%clc; clear;
function plotPaper02_PSD_HFG
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
SimRunDir = 'Simulation_Run_at_28-Dec-23_10-44-58'; % opt I=P =0. 7, 16

% SimDir = fullfile('Simulation_Run_at_05-Sep-23_23-34-28','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_13-Dec-23_16-55-14','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_14-Dec-23_11-24-11','Results_16mps'); %opt I (IPC) P (IFC)
% SimDir = fullfile('Simulation_Run_at_14-Dec-23_12-29-32','Results_16mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_16mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_25mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_18mps'); %opt PID (IPC) PID (IFC)
SimDir = fullfile(SimRunDir,'Results_16mps'); %opt PID (IPC) PID (IFC)

legendCellNew =  [{'Baseline control and '}
    {'IPC'}
    {'TEFC'}
    {'IPC + TEFC'}];

PostprocessingFolder = fullfile(MainFolder,'Post_processing_for_plots',SimDir);

dirFig = 'fig2';
if ~isfolder(dirFig)
    mkdir(dirFig);
end

plotAll = 0;

figureInDir = dir(fullfile(PostprocessingFolder,'5MW_Land*.fig'));
lenDir = length(figureInDir);

XDataCell = cell(lenDir,2);
YDataCell = cell(lenDir,2);
% XDataCellE = cell(lenDir,1);
% YDataCellE = cell(lenDir,1);

legendCell = cell(lenDir,1);
strIFC = 'TEFC'; %'IFC';
no = lenDir+1;

for idxF = 1:length(figureInDir)

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
vec2 = [1,4];


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
filenamepng = 'fig02_PSDroot_breaky';
filepathpng = fullfile(dirFig,filenamepng);
titleStr = ['            ', legendCell{1}, ...
    '; \color{blue}' legendCell{2}, '; \color[rgb]{0,0.5,0}' legendCell{3}];
plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type,titleStr)

cCell = {'black','blue','green','red'};
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
cl = {'k-','b-','g-.','r--'};
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

    for idxP =  vec1
        plot(XDataCell{idxP,1},YDataCell{idxP,1},cl{idxP},'linewidth',lw);
        hold on;
    end
    axis tight; grid on;
    ylimOrig = get(gca,'YLim');

    temp = YDataCell(:,2);
    str1 = cell(2*length(temp),1);
    for idxS = 1:length(temp)
        str1{idxS} = sprintf('%2.2e', temp{idxS}(1));
        str1{idxS+length(temp)} = sprintf('%2.2e', temp{idxS}(2));
    end

    if type == 1

        set(gca,'YLim',[ylimOrig(1),5.5*10^7])
        legend(legendCell(vec1),'FontSize',fs-1);


        % Create textarrow for BL
        annotation(gcf,'textarrow',[0.426 0.376],[0.842 0.906],...
            'String',str1(1),...
            'FontSize',12);
        annotation(gcf,'textarrow',[0.640476190476187 0.590476190476188],...
            [0.471663139329804 0.536155202821867],'String',str1(1 + 4),'FontSize',12);


        if  any(vec1 == 2) %length(vec1) == 3

            % Create textarrow for IPC
            annotation(gcf,'textarrow',[0.42738095238095 0.398809523809524],...
                [0.316460317460316 0.27689594356261],'Color',[0 0 1],'String',str1(2),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.641666666666664 0.591666666666665],...
                [0.603938271604936 0.668430335097],'Color',[0 0 1],'String',str1(2+4),...
                'FontSize',12);
        end

        if  any(vec1 == 3)
            % Create textarrow for TEF
            annotation(gcf,'textarrow',[0.426190476190474 0.376190476190475],...
                [0.759141093474426 0.82363315696649],'Color',[0 0.6 0],...
                'String',str1(3),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.646428571428567 0.617857142857142],...
                [0.282950617283948 0.243386243386243],'Color',[0 0.6 0],...
                'String',str1(3+4),...
                'FontSize',12);
        end
        if  any(vec1 == 4)

            % Create textarrow for IPC-TEF
            annotation(gcf,'textarrow',[0.42738095238095 0.398809523809524],...
                [0.316460317460316 0.27689594356261],'Color',c,'String',str1(4),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.646428571428567 0.617857142857142],...
                [0.282950617283948 0.243386243386243],'Color',c,...
                'String',str1(4+4),...
                'FontSize',12);

        end


    elseif type == 2

        xlabel(xlabelStr, 'FontSize',fs);
        ylabel(ylabelStr,'FontSize',fs);

        d = 0.01*(ylimOrig(2)- ylimOrig(1));
        set(gca,'YLim',[ylimOrig(1),ylimOrig(2)+d])

        outBreakAxis =  breakyaxis([0.32*10^8,2.3*10^8]); % 1.4
        outBreakAxis.highAxes.Title.String = titleStr;
        outBreakAxis.highAxes.Title.FontSize = fs;
        outBreakAxis.highAxes.FontSize = fs-2;

        % Create textarrow for Baseline
        annotation(gcf,'textarrow',[0.426190476190475 0.36547619047619],...
            [0.84479717813051 0.876543209876543],'String',str1(1),'FontSize',12);
        annotation(gcf,'textarrow',[0.653571428571426 0.592857142857142],...
            [0.544973544973542 0.576719576719575],'String',str1(1+4),'FontSize',12);

        if  any(vec1 == 2)

            % Create textarrow for IPC
            annotation(gcf,'textarrow',[0.426190476190475 0.397619047619047],...
                [0.289241622574955 0.218694885361551],'Color',[0 0 1],'String',str1(2),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.653571428571426 0.592857142857141],...
                [0.60670194003527 0.638447971781303],'Color',[0 0 1],'String',str1(2+4),...
                'FontSize',12);
        end

        if  any(vec1 == 3)

            % Create textarrow for TEF
            annotation(gcf,'textarrow',[0.421428571428571 0.370238095238095],...
                [0.746031746031746 0.701940035273368],'Color',[0 0.6 0],...
                'String',str1(3),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.623809523809521 0.595238095238094],...
                [0.294532627865959 0.223985890652556],'Color',[0 0.6 0],...
                'String',str1(3+4),...
                'FontSize',12);
        end

        if  any(vec1 == 4)
            % Create textarrow for IPC-TEF
            annotation(gcf,'textarrow',[0.426190476190475 0.397619047619047],...
                [0.289241622574955 0.218694885361551],'Color',c,'String',str1(4),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.623809523809521 0.595238095238094],...
                [0.294532627865959 0.223985890652556],'Color',c,...
                'String',str1(4+4),...
                'FontSize',12);
        end

    end

end

xlabel(xlabelStr, 'FontSize',fs);
ylabel(ylabelStr,'FontSize',fs);

print(gcf,filepathpng, '-dpng');
print(gcf,filepathpng, '-depsc');
