%clc; clear;
function nF = plotPaper02_PSD_comparison(nF,mP)

if ~nargin
    close all;
    nF = 1;
    addpath(genpath('breakyaxis'));
end

if nargin<2
    mP = 0.65;
end


dirFig = 'fig2';
if ~isfolder(dirFig),  mkdir(dirFig); end
plotAll = 0;
newLegend = 1;

ws = 16;
strlegBL = 'TEFC: off, IPC: off';
strlegBLNew = 'Baseline';
strlegIPC = 'TEFC: off, IPC: on';
strlegIPCNew = 'IPC';

legendCellNew =  [{'Baseline'}
    {'IPC'}
    {'IFC'}
    {'AALC'}
    {'AALC'}];

MainFolder = fileparts(pwd);

SimRunDir = 'SimInitCtrl_P1_I1'; %'Simulation_Run_at_13-Dec-23_16-55-14'; % orig: I = 1 (IPC), P = 1 (IFC)
SimRunDirComp = 'SimOptCtrl_PID'; % opt PID (IPC) PID (IFC): mod. ADi

SimDir = fullfile(SimRunDir,sprintf('Results_%dmps',ws)); %opt PID (IPC) PID (IFC)
SimDirComp = fullfile(SimRunDirComp ,sprintf('Results_%dmps',ws)); %opt PID (IPC) PID (IFC)


SimDirCell = {SimDir,SimDirComp};

for idxDir = 1: 2
    SimDir = SimDirCell{idxDir};
    PostprocessingFolder = fullfile(MainFolder,'Post_processing_for_Plots',SimDir);

    figureInDir = dir(fullfile(PostprocessingFolder,'5MW_Land*.fig'));
    lenDir = length(figureInDir);

    if idxDir == 1
        XDataCell = cell(lenDir,2);
        YDataCell = cell(lenDir,2);
        legendCell = cell(lenDir,1);
    end
    strIFC = 'TEFC'; %'IFC';
    no = lenDir+1;

    if idxDir == 1
        idxFvec = 1:length(figureInDir);
    else
        idxFvec = length(figureInDir);
    end

    for idxF = idxFvec

        fname = figureInDir(idxF).name;
        fig = openfig(fullfile(PostprocessingFolder, fname));

        dataXObjs = findobj(fig,'-property','XData'); %dataYObjs = findobj(fig,'-property','YData');

        XdataAll = get(dataXObjs,'Xdata'); %
        YdataAll = get(dataXObjs,'Ydata'); %
        [~, idx]  = max(cellfun('length',XdataAll)); % pick the data not the extrema
        [~, idxE]  = min(cellfun('length',XdataAll)); % pick the extrema

        XdataAllOut = XdataAll{idx};
        YdataAllOut = YdataAll{idx};

        idx1 = XdataAllOut <= 0.7;

        legTemp = strrep(strrep(fname,'5MW_Land.SFunc_',''),'.fig','');
        legTemp2 = strrep(strrep(legTemp,'_IPC',', IPC'),'_',': ');
        legTemp2 = strrep(legTemp2,'TEF',strIFC);

        if idxDir == 2
            idxF = idxF +1;
        end

        XDataCell{idxF,1} = XdataAllOut(idx1);
        YDataCell{idxF,1} = YdataAllOut(idx1);

        XDataCell{idxF,2} = XdataAll{idxE};
        YDataCell{idxF,2} = YdataAll{idxE} ;

        legendCell{idxF} = legTemp2;

    end
    %close all;
end

if newLegend == 1
    legendCell = legendCellNew;
end
% xlabelStr = 'Frequency, Hz';
% ylabelStr = 'PSD Blade root flapwise moment, kNm^2/Hz';
% cl = {'k-','b--','g-.','r--'};
% fs = 12;
% lw = 0.7;

vec1 = 1:3;
%v1 = vec1(end);
vec2 = [1,4,5];

%% Plot 9&10: lin scale, split y axis
type = 2;
no = lenDir + 4 + nF;
filenamepng = 'fig02_PSDroot_breaky';
filepathpng = fullfile(dirFig,filenamepng);
titleStr = ['            ', legendCell{1}, ...
    '; \color{blue}' legendCell{2}, '; \color[rgb]{0,0.5,0}' legendCell{3}];
plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type,mP,titleStr)


cCell = {'black','blue','green','red','magenta'};
%Cvec = [[1,1,1];[0,0,1];[0,1,0];[1,0,0]];
v2c = vec2(end-1:end);
cC = cCell(v2c);

filenamepng = 'fig02_PSDroot_breaky1c';
no = lenDir + 5 + nF;
filepathpng = fullfile(dirFig,filenamepng);
titleStr = ['  ', legendCell{1}, '; \color{',cC{1},'}' legendCell{v2c(1)},...
    '; \color{',cC{2},'}' legendCell{v2c(2)},' opt.'];
plotPSD(no,vec2,XDataCell,YDataCell,legendCell,filepathpng,type,mP,titleStr)


function plotPSD(no,vec1,XDataCell,YDataCell,legendCell,filepathpng,type,mP,titleStr)

if nargin < 9
    titleStr = '';
end

xlabelStr = 'Frequency, Hz';
%ylabelStr = 'PSD Blade root flapwise moment, kNm^2/Hz';
ylabelStr = {'PSD Blade root flapwise moment,' 'kNm^2/Hz'};
cl = {'k-','b-','g-.','r--','m-.'};
fs = 12;
lw = 0.8;

v2 = vec1(end);
Cvec = [[1,1,1];[0,0,1];[0,1,0];[1,0,0];[1,0,1]];
c = Cvec(v2,:);

nf = figure(no);
nfpos = get(0,'defaultFigurePosition');
nf.Position= [nfpos(1:3), nfpos(4)*mP];

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
    lStr = length(temp); %number of test cases
    for idxS = 1:lStr
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
            [0.471663139329804 0.536155202821867],'String',str1(1 + lStr),'FontSize',12);


        if  any(vec1 > 2) && length(vec1) ~= 3

            % Create textarrow for IPC
            annotation(gcf,'textarrow',[0.42738095238095 0.398809523809524],...
                [0.316460317460316 0.27689594356261],'Color',[0 0 1],'String',str1(2),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.641666666666664 0.591666666666665],...
                [0.603938271604936 0.668430335097],'Color',[0 0 1],'String',str1(2+4),...
                'FontSize',12);
        end

        if  any(vec1 == 3) && vec1(end) == 3
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
                [0.316460317460316 0.27689594356261],'Color',Cvec(4,:),'String',str1(4),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.646428571428567 0.617857142857142],...
                [0.282950617283948 0.243386243386243],'Color',Cvec(4,:),...
                'String',str1(4+lStr),...
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
            [0.544973544973542 0.576719576719575],'String',str1(1+lStr),'FontSize',12);

        if  any(vec1 == 2)

            % Create textarrow for IPC
            annotation(gcf,'textarrow',[0.426190476190475 0.397619047619047],...
                [0.289241622574955 0.218694885361551],'Color',[0 0 1],'String',str1(2),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.653571428571426 0.592857142857141],...
                [0.60670194003527 0.638447971781303],'Color',[0 0 1],'String',str1(2+lStr),...
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
                'String',str1(3+lStr),...
                'FontSize',12);
        end

        if  any(vec1 == 4)

            % Create textarrow for IPC-TEF
            annotation(gcf,'textarrow',[0.428 0.399],...
                [0.316460317460316 0.27689594356261],'Color',Cvec(4,:),'String',str1(4),...
                'FontSize',12);
            annotation(gcf,'textarrow',[0.647 0.618],...
                [0.282950617283948 0.243386243386243],'Color',Cvec(4,:),...
                'String',str1(4+lStr),...
                'FontSize',12);
        end

        if  any(vec1 == 5)

            % Create textarrow for IPC-TEF
            annotation(gcf,'textarrow',[0.44047619047619 0.413095238095237],...
                [0.257495590828924 0.206349206349206],'Color',Cvec(5,:),'String',str1(5),...
                'FontSize',12);


            annotation(gcf,'textarrow',[0.638095238095237 0.610714285714284],...
                [0.335097001763668 0.28395061728395],'Color',Cvec(5,:),...
                'String',str1(5+lStr),...
                'FontSize',12);

        end

    end

end

% tempMat = cell2mat(temp); %For debugginh

% BL_IPCIFC0_1P = (tempMat(1,1) -tempMat(4,1))/tempMat(1,1);
% BL_IPCIFCopt_1P = (tempMat(1,1) -tempMat(5,1))/tempMat(1,1);
% 
% BL_IPCIFC0_2P = (tempMat(1,2) -tempMat(4,2))/tempMat(1,2);
% BL_IPCIFCopt_2P = (tempMat(1,2) -tempMat(5,2))/tempMat(1,2);
% 
% IPCIFCopt_1P = (tempMat(4,1) -tempMat(5,1))/tempMat(4,1);
% IPCIFCopt_2P = (tempMat(4,2) -tempMat(5,2))/tempMat(4,2);

xlabel(xlabelStr, 'FontSize',fs);
ylabel(ylabelStr,'FontSize',fs);

print(gcf,filepathpng, '-dpng');
print(gcf,filepathpng, '-depsc');

% Unused directories
%SimRunDir = 'Simulation_Run_at_18-Dec-23_12-15-11';
%SimRunDir = 'Simulation_Run_at_14-Dec-23_11-24-11'; % opt I (IPC) P (IFC)
%SimRunDir = 'Simulation_Run_at_14-Dec-23_12-29-32'; % opt PID (IPC) PID (IFC):
%SimRunDir = 'Simulation_Run_at_14-Dec-23_13-17-41'; % opt PID (IPC) PID (IFC): mod. ADi (P Ipc = 1.1
%SimRunDir = 'Simulation_Run_at_14-Dec-23_14-08-28'; % opt PID (IPC) PID (IFC): mod. ADi
%SimRunDir = 'Simulation_Run_at_14-Dec-23_14-35-37'; % opt PID (IPC) PID (IFC): mod. ADi
%SimRunDirComp ='Simulation_Run_at_18-Dec-23_12-39-25';
% SimDir = fullfile('Simulation_Run_at_05-Sep-23_23-34-28','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_13-Dec-23_16-55-14','Results_16mps');
% SimDir = fullfile('Simulation_Run_at_14-Dec-23_12-29-32','Results_16mps'); %opt PID (IPC) PID (IFC)
% SimDir = fullfile(SimRunDir,'Results_25mps'); %opt PID (IPC) PID (IFC)
