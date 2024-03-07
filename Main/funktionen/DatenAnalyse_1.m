clear all
close all

%% > Pfade speichern <
%    Pfad zum Main-Ordner speichern
mainFolder = [pwd];
%    Pfad zum Programmordner speichern
[programm_filepath,~,~] = fileparts(pwd);


%% Angabe des MCrunch Archivs 
Location_MCrunch_Archiv_Folder = [programm_filepath filesep 'Post_processing' filesep 'MCrunch' filesep 'Archiv' filesep 'Archiv_1'];


%% Analyse der Leistungsdichtespektren
% Einlesen der Daten 
filename = [Location_MCrunch_Archiv_Folder filesep 'Analyse_PSDs.xls'];
sheet = 2;
PSD_Data(:,1:2) = xlsread(filename,sheet);
sheet = 3;
PSD_Data(:,3:4) = xlsread(filename,sheet);

j = 1;
for i = 1 : 2    
    [pks(:,i) , locs(:,i)] = find_P(PSD_Data(:, j : j+1) );
    j = j + 2;
end 


%% Plotten der Leistungsdichtesprktren
figure 
j = 1;
for i = 1 : 2
    plot(PSD_Data(:, j), PSD_Data(:, j+1),...
         locs(:,i), pks(:,i));
    hold on
    j = j + 2;
end 

grid on
xlim([0 1]);
title('Leistungsdichtespektren');
xlabel('Frequenz [Hz]');
legend({'ohne Klappenregelung','Maxima','mit Klappenregelung','Maxima'});

%% Relative Änderungen der Maxima berechnen

rel_delta_pks = 100*(pks(:,2) - pks(:,1)) ./ pks(:,1);

%% Ausgabe der Ergebnisse
fprintf('\nRelative Ängerung der Maxima fuer P1, P2 und P3:\n');
for i = 1 : length(rel_delta_pks)
   fprintf('P%d: %.2f \n',i,rel_delta_pks(i));
end

%% Funktionen
function [pks, locs ] = find_P(PSD_Data)
%% Suchen der lokalen Maxima
[pks,locs] = findpeaks(PSD_Data(:,2),PSD_Data(:,1),'MinPeakDistance',0.1);

%% Wertepare für P1 P2 P3 extrahiren
pks = pks(2:4);
locs = locs(2:4);
end







