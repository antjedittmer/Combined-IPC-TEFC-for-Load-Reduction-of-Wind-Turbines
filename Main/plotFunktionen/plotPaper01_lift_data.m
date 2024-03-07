function nF = plotPaper01_lift_data(nF,mP)

if ~nargin
    clc; clear; close all;
    nF = 0; % number of figure added to  1:3
end

if nargin < 2
    mP = 0.7;
end

%% Constants for reading in data and plotting
fs = 13.5; % font size
lw = 0.75; % line width
ms = 4; % max
maxA = 50; % max. displayed angle
%xlabelStr = ['Angle of attack \alpha (', s,')']
xlabelStr = 'Angle of attack \alpha, deg';

lgIn = 0;

if lgIn == 1
    strPng = '1';
else
    strPng = '1out';
end

dirMain= fileparts(pwd);
dir5MW = fullfile(fileparts(dirMain),'FAST_Sim_TEF','5MW-Turbine-Inputfiles');
dirFlaps = fullfile(dir5MW,'Sub-Inputfiles','Airfoils_Flaps_Re_angepasst');
filenamepath = fullfile(dirFlaps,'NACA64_A17_Flap.dat');

str1 = '-180.00'; % this string marks the beginning of the table
cnt = 0; %counter table rows
hTab = 142; % 142 rows in each table
cntF = 1; %counter files/angles

dirFig = 'fig1'; %dirFig = pwd;
if ~isfolder(dirFig)
    mkdir(dirFig);
end

strOut = 'TEFaero';

if ~isfolder(dirFig)
    mkdir(dirFig);
end

%% Read in data from NACA64_A17_Flap.dat
fid = fopen(filenamepath);
frewind(fid);
line_ex = fgetl(fid);
% disp(line_ex);

while line_ex ~= -1
    line_ex = fgetl(fid);
    if line_ex ~= -1
        % disp(line_ex);
        if contains(line_ex, str1)

            fileID = fopen(sprintf('%s%02d.txt',strOut,cntF),'w');
            fprintf(fileID,'%s\n',line_ex);
            cnt = cnt +1;
        elseif cnt >= 1 && cnt <hTab

            fprintf(fileID,'%s\n',line_ex);
            cnt = cnt +1;
        elseif cnt == hTab

            fclose(fileID);
            cnt = 0; % reset line counter
            cntF = cntF +1; % update file/angle counter
        end
    end
end

fclose(fid);

%% Assign data
noA = cntF; % hTab/lenTab;
AeroDatenS1 = cell(noA,1);
varnames = {'Alpha','Cl','Cd','Cm'};
ylabStr = {'lift ','drag ','moment '};

for idx = 1: noA
    fName = sprintf('%s%02d.txt',strOut,idx);
    NACA64A17FlapC = readtable(fName);
    NACA64A17FlapC.Properties.VariableNames = varnames;
    AeroDatenS1{idx} = NACA64A17FlapC;
end

%% Plot data
s = sprintf('%c', char(176));
lgCell = {['Flap -10',s] ;['Flap -7',s] ;['Flap -3',s] ;['Flap 0',s] ;['Flap 3',s] ;['Flap 7',s] ;['Flap 10',s] };
lgCell = strrep(lgCell,'Flap ','\eta_{TEF} = ');
lgCell1 = strrep(lgCell,'\eta_{TEF} = ','\eta_{TEF}: ');

locCell = {'SouthEast','North','NorthEast'};
mCell = {'o','*','.','x','d','>','^'};

for idxL = 1:3

    ldmName = varnames{idxL+1};
    filenamepng = ['fig01_',ldmName,strPng];

    ylabelStr = ['NACA64 ',ylabStr{idxL},strrep(ldmName,'C','c_')];

    nf = figure(idxL + nF);
    nfpos = nf.Position;nf.Position= [nfpos(1:2),  nfpos(3) nfpos(4) *mP];

    idxmaxA = abs(AeroDatenS1{1}.Alpha) <= maxA;

    for idx = 1: noA
        tmp = AeroDatenS1{idx}.(ldmName);
        plot(AeroDatenS1{idx}.Alpha(idxmaxA), tmp(idxmaxA),[mCell{idx},'-'],'Linewidth',lw,'MarkerSize',ms); hold on;
    end
    hold off;

    axis tight; grid on;
    if lgIn == 1
        legend(lgCell,'Location', locCell{idxL},'Fontsize',fs-1)
    else
        legend(lgCell1,'Fontsize',fs-1,...
            'Location','northoutside','NumColumns',4)
    end

    xlabel(xlabelStr, 'FontSize',fs);
    ylabel(ylabelStr,'FontSize',fs);

    ylimOrig = get(gca,'YLim');
    d = 0.05*(ylimOrig(2)- ylimOrig(1));
    set(gca,'YLim',[ylimOrig(1)-d,ylimOrig(2)+d])

    set(gca,'Xtick',-maxA:10:maxA)

    print(gcf,fullfile(dirFig,filenamepng), '-dpng');
    print(gcf,fullfile(dirFig,filenamepng), '-depsc');
end

nF = nf.Number;
