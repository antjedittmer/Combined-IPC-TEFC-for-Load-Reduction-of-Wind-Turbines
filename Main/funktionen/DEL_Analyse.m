clear all
close all

%% > Pfade speichern <
%    Pfad zum Main-Ordner speichern
mainFolder = [pwd];
%    Pfad zum Programmordner speichern
[programm_filepath,~,~] = fileparts(pwd);


%% Angabe des MCrunch Archivs 
Location_MCrunch_Archiv_Folder = [programm_filepath filesep 'Post_processing' filesep 'MCrunch' filesep 'Archiv' filesep 'Archiv_1'];


%% Analyse der DELs
% Einlesen der Daten 
filename = [Location_MCrunch_Archiv_Folder filesep 'Analyse_DELs.xls'];
xlRange = 'E5:F7';
DEL_Data = xlsread(filename,xlRange);

%% Analyse

delta_DEL = DEL_Data(:,2) - DEL_Data(:,1);
rel_delta_DEL = 100.*delta_DEL./DEL_Data(:,1);

%% Ausgabe der Ergebnisse
fprintf('\nRelative Ängerung der DELs fuer RootMyb1, RootMyb2 und RootMyb3:\n');
for i = 1 : length(rel_delta_DEL)
   fprintf('RootMyb%d: %.2f \n',i,rel_delta_DEL(i));
end

