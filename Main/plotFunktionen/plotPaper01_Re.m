%clc; clear; close all,
function nF = plotPaper01_Re(nF)
% Re via Grabit from Master Thesis
if ~nargin
    clc; clear; close all;
    nF = 1; % number of figure
end

dirMain = fileparts(pwd);
dir5MW = fullfile(fileparts(dirMain),'FAST_Sim_TEF','5MW-Turbine-Inputfiles');
dirFlaps = fullfile(dir5MW,'Sub-Inputfiles','Airfoils_Flaps_Re_angepasst');

dirFig = 'fig1'; %dirFig = pwd;
if ~isfolder(dirFig)
    mkdir(dirFig);
end

% openFAST-Tool-Masterarbeit\FAST_Sim_TEF\5MW-Turbine-Inputfiles\Sub-Inputfiles\Airfoils_Flaps_Re_angepasst
dirRotorblade = fullfile(dirFlaps,'Fig1');
dirJpg = 'DataOL';
fig1Path1 = fullfile(dirJpg,'RotorblattEng.jpg');
fig1Path2 = fullfile(dirJpg,'RotorblattEng1.jpg');

Re = [1.7493    0.0304
    3.0966    0.2896
    5.8113    0.3402
    8.5329    0.4505
    11.8516    0.5779
    15.9320    0.7357
    20.0629    0.8510
    23.8669    0.9482
    28.1032    1.0272
    32.1208    1.0850
    36.1378    1.1367
    40.0995    1.1763
    44.1129    1.1856
    48.1795    1.1828
    52.1363    1.1648
    55.5503    1.1408
    58.2561    1.0773
    60.7783    0.7714
    62.1349    0.7836];

Re(:,2) = Re(:,2)*10^7;

fs = 12;
lw = 0.7;
%xlabelStr = ['Angle of attack \alpha (', s,')']
xlabelStr = 'Rotor radius, m';
ylabelStr = 'Reynolds number Re';



%% Plot 1 (with 3D contours)
nf = figure(nF);
nfpos = nf.Position;
nf.Position= [nfpos(1:2),  nfpos(3) nfpos(4) *0.9];

subplot(2,1,1)
plot(Re(:,1),Re(:,2),'*-','Linewidth',lw,'MarkerSize',4);

axis tight; grid on; 
xlabel(xlabelStr, 'FontSize',fs);
ylabel(ylabelStr,'FontSize',fs);

ylimOrig = get(gca,'YLim');
d = 0.05*(ylimOrig(2)- ylimOrig(1));
set(gca,'YLim',[ylimOrig(1)-d,ylimOrig(2)+d])

FG = imread(fig1Path1);

% i'm going to expand the image to make sure it's RGB
% this avoids issues dealing with colormapped objects in the same axes
if size(FG,3) == 1
    FG = repmat(FG,[1 1 3]); 
end

% the origin of an image is the NW corner
% so in order for both the plot and image to appear right-side up, flip the image
% FG = flipud(FG);
% subplot(2,1,2)
axes('pos',[0.12 0.05 .805 .4])
image(FG,'xdata',[0 1],'ydata',[0 1])
set(gca,'XColor', 'none','YColor','none')

filenamepng = 'fig01_RE';
print(gcf,fullfile(dirFig,filenamepng), '-dpng');
print(gcf,fullfile(dirFig,filenamepng), '-depsc');


%% Plot 2 (with 3D contours)
nf = figure(nF+1);
nfpos = nf.Position;nf.Position= [nfpos(1:2),  nfpos(3) nfpos(4) *0.9];

% RE plot
subplot(3,1,[1,2])
plot(Re(:,1),Re(:,2),'*-','Linewidth',lw,'MarkerSize',4);
axis tight; grid on; 
xlabel(xlabelStr, 'FontSize',fs);
ylabel(ylabelStr,'FontSize',fs);

ylimOrig = get(gca,'YLim');
d = 0.05*(ylimOrig(2)- ylimOrig(1));
set(gca,'YLim',[ylimOrig(1)-d,ylimOrig(2)+d])

% Rotorblat
FG = imread(fig1Path2);

% i'm going to expand the image to make sure it's RGB
% this avoids issues dealing with colormapped objects in the same axes
if size(FG,3) == 1
    FG = repmat(FG,[1 1 3]); 
end

% the origin of an image is the NW corner
% so in order for both the plot and image to appear right-side up, flip the image
% FG = flipud(FG);
% subplot(2,1,2)
axes('pos',[0.12 0.02 .805 .25])
image(FG,'xdata',[0 1],'ydata',[0 1])
set(gca,'XColor', 'none','YColor','none')

filenamepng = 'fig01_RE1';
print(gcf,fullfile(dirFig,filenamepng), '-dpng');
print(gcf,fullfile(dirFig,filenamepng), '-depsc');

nF = nf.Number;

return;


figure; %#ok<UNRCH>; Example from Matlab answer
t = linspace(0,pi,100);
y = sin(2*t);
plot(t,y); hold on; grid on
% an image

% i'm going to expand the image to make sure it's RGB
% this avoids issues dealing with colormapped objects in the same axes
if size(FG,3) == 1
    FG = repmat(FG,[1 1 3]); 
end
% the origin of an image is the NW corner
% so in order for both the plot and image to appear right-side up, flip the image
FG = flipud(FG);
% insert an image in a particular region in the current axes
% this uses image(); similar can be done with imshow()/imagesc()
image(FG,'xdata',[0 pi/4],'ydata',[0 pi/4])
axis equal

