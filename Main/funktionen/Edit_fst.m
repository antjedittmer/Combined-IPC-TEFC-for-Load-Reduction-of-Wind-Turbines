function [] = Edit_fst(FAST_InputFileName,StartTimeLogOutput)
%EDIT_FST Summary of this function goes here
%   Detailed explanation goes here

% Einlesen der fst-Datei
lines = readlines(FAST_InputFileName);

% Neue Zeile erzeugen
StartTimeStr = convertCharsToStrings(int2str(StartTimeLogOutput));
string = StartTimeStr.append( "        TStart          - Time to begin tabular output (s)");

% ersetzen der Zeile 49
lines(49) = string;

% erzeugen der neuen fst-Datei
fileID = fopen(FAST_InputFileName,'w'); 
for j = 1 : length(lines)
    fprintf(fileID, '%s \n', lines(j));
end 

fclose(fileID);
end

