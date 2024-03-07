function [FileName] = Edit_InflowWind_V2(Loc_bts_file, i ,InflowWind_InputFilePath)
%EDTIT_INFLOWWIND Summary of this function goes here
%   Ersetzt die zwanzigste Zeile von
%   NRELOffshrBsline5MW_InflowWind_12mps.dat mit dem Pfand der .bts-Datei,
%   welche verwendet werden soll

%   Inputs:
%   Loc_bts_file = String-Vektor mit den Pfaden der bts-Datein
%   i = integer, der Angibt welcher Pfad verwendet werden soll
%   InflowWind_InputFilePath = Pfad zur InflowWind-Datei

[~,FileName,~] = fileparts(Loc_bts_file(i));
FileName = convertStringsToChars(FileName);

lines = readlines(InflowWind_InputFilePath);

Loc_bts_file = strcat(['"'], Loc_bts_file(i), ['"']);
string = Loc_bts_file.append( "     FileName_BTS   - Name of the Full field wind file to use (.bts)");

% ersetzen der Zeile 21
lines(21) = string;

% erzeugen der neuen InflowWind.dat
fileID = fopen(InflowWind_InputFilePath,'w'); 
for j = 1 : length(lines)
    fprintf(fileID, '%s \n', lines(j));
end  
fclose(fileID);

end

