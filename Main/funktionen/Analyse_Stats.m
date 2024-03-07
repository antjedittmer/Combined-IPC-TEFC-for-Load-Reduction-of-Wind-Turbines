clear all
close all

%% > Pfade speichern <
%    Pfad zum Main-Ordner speichern
mainFolder = [pwd];
%    Pfad zum Programmordner speichern
[programm_filepath,~,~] = fileparts(pwd);


Location_MCrunch_Archiv_Folder = [programm_filepath filesep 'Post_processing' filesep 'MCrunch' filesep 'Archiv'];

i = 1;
filenames=dir(Location_MCrunch_Archiv_Folder);                                 % Liste der Dateinamen in Processing_folder erstellen
for z=3:length(filenames) 

    Location_Archiv_Folder = [Location_MCrunch_Archiv_Folder filesep 'Archiv_' int2str(i)];


    %% Angabe des MCrunch Archivs 
    %Location_Archiv_Folder = [programm_filepath filesep 'Post_processing' filesep 'MCrunch' filesep 'Archiv' filesep 'Archiv_2'];

    % Einlesen der Daten 
    filename = [Location_Archiv_Folder filesep 'Analyse_Stats.xls'];

    numVars = 8;
    varNames = {'Parameter','Units','Minimum','Mean','Maximum','StdDev','Skewness', 'Range'};
    varTypes = {'char','char','double', 'double', 'double' ,'double' ,'double', 'double'} ;

    opts = spreadsheetImportOptions('NumVariables',numVars, 'VariableNames',varNames, 'VariableTypes',varTypes);
    opts.Sheet = 2;
    opts.DataRange = 'A7:H151';

    Stats_Data_1 = readtable(filename,opts);
    clear opts

    opts = spreadsheetImportOptions('NumVariables',numVars, 'VariableNames',varNames, 'VariableTypes',varTypes);
    opts.Sheet = 3;
    opts.DataRange = 'A7:H147';

    Stats_Data_2 = readtable(filename,opts);

    % Daten Auswertung
    Mean_rel_diff = (Stats_Data_2.Mean(28) - Stats_Data_1.Mean(28))*100/Stats_Data_1.Mean(28);

    StdDev_rel_diff = (Stats_Data_2.StdDev(28) - Stats_Data_1.StdDev(28))*100/Stats_Data_1.StdDev(28);

    % Ausgabe der Ergebnisse
    fprintf('\n---------------------------------------------------------\n');
    fprintf('Archiv_%d \n',i);
    fprintf('Parameter = RootMyb1 [kNm]\n');
    fprintf('Relative Aenderung des Mittelwerts        = %f [%%] \n', Mean_rel_diff);
    fprintf('Relative Aenderung der Standardabweichung = %f [%%] \n', StdDev_rel_diff);
    fprintf('---------------------------------------------------------\n');
    i = i + 1;
    clear Location_Archiv_Folder
end



