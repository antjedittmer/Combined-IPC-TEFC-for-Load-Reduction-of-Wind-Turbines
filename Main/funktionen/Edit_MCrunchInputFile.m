function [] = Edit_MCrunchInputFile(AnlyseFolderPath, MCrunch_InputFilePath, MeanWindSpeed)
%EDIT_MCRUNCHINPUTFILE Summary of this function goes here
%   Detailed explanation goes here

[~,mcru_FileName] = fileparts(MCrunch_InputFilePath);
mcruFilePath = append(fullfile(AnlyseFolderPath, mcru_FileName), '.mcru');

% Eintragen der Mittlerenwindgeschwindigkeit

lines = readlines(mcruFilePath);
line = 0;
for i = 1 : length(lines)                                                  % Suche nach der Zeile in der man die Rayleigh-average wind speed angeben muss
    x = contains(lines(i),"RayAverWS");    
    if x == 1
        line = i;
    end
end

if line == 0                                                               % Fehlermeldung falls die Zeile zur Angabe der Rayleigh-average wind speed nicht gefunden wurde
    fprintf('Fehler! Es besteht ein Fehler beim Einlesen der .mcru-Datei. Wahrscheinlich ist die mcru-Datei nicht richtig Ausgefüllt\n');
    return;
end

% Angeben der der Rayleigh-average wind speed
lines(line) = strcat(int2str(fliplr(MeanWindSpeed)), "                RayAverWS         Rayleigh-average wind speed.");


% Überprüfen welche PAST.out Dateinen im Analyseordner vorhanden sind
FileList = dir(AnlyseFolderPath);
k = 1;
for i = 1 : length(FileList)    
    [~, ~, ext] = fileparts(FileList(i).name);
    if ext == ".out"
    FASToutFileList(k) = convertCharsToStrings(FileList(i).name);
    k = k + 1;
    end  
end

NumFiles = length(FASToutFileList);

% Anpassen der mcru-Datei an vorhandene FAST.out Datein
% lines = readlines(mcruFilePath);
line = 0;
for i = 1 : length(lines)                                                  % Suche nach der Zeile in der die Anzahl der FAST.out Dateien angegeben werden muss
    x = contains(lines(i),"NumFiles");    
    if x == 1
        line = i;
    end
end

if line == 0                                                               % Fehlermeldung falls die Zeile zur Angabe der Anzahl der FAST.out Dateien nicht gefunden wurde
    fprintf('Fehler! Es besteht ein Fehler beim Einlesen der .mcru-Datei. Wahrscheinlich ist die mcru-Datei nicht richtig Ausgefüllt\n');
    return;
end

% Angeben der Anzahl der input files to read
lines(line) = strcat(int2str(NumFiles), "                 NumFiles          The number of input files to read.");

% Angeben der input files
for i = 1 : length(FASToutFileList)
    lines(line + i) = strcat(['"'], FASToutFileList(i), ['"']);
end

% letzte Zeile der mcru.Datei einfügen
lines(line + i + 1) = "==EOF==                             DO NOT REMOVE OR CHANGE.  MUST COME JUST AFTER LAST LINE OF VALID INPUT.";
    
% Erzeugen der neuen .mcru Datei
fileID = fopen(mcruFilePath,'w'); 
for j = 1 : length(lines)
    fprintf(fileID, '%s \n', lines(j));
end  
fclose(fileID);

end

