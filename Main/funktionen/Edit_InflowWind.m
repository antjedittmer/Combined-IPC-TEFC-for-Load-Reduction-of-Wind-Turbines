function [] = Edit_InflowWind(Loc_bts_file, i ,InflowWind_Folder)
%EDTIT_INFLOWWIND Summary of this function goes here
%   Ersetzt die zwanzigste Zeile von
%   NRELOffshrBsline5MW_InflowWind_12mps.dat mit dem Pfand der .bts-Datei,
%   welche verwendet werden soll

%   Inputs:
%   Loc_bts_file = String-Vektor mit den Pfaden der bts-Datein
%   i = integer, der Angibt welcher Pfad verwendet werden soll
%   InflowWind_Folder = Pfad zum Ordner der InflowWind-Datei
%   "InflowWind_Ref.dat" = referenz InflowWindDatei

lines = readlines("InflowWind_Ref.dat");

Loc_bts_file = strcat(['"'], Loc_bts_file(i), ['"']);
string = Loc_bts_file.append( "     Filename       - Name of the Full field wind file to use (.bts)");

% ersetzen der Zeile 20
lines(20) = string;

% erzeugen der neuen InflowWind.dat
fileID = fopen('NRELOffshrBsline5MW_InflowWind_12mps.dat','w'); 
for j = 1 : length(lines)
    fprintf(fileID, '%s \n', lines(j));
end  
fclose(fileID);

% verschieben der neuen InflowWind.dat in den richtigen Ordner
movefile([pwd filesep 'NRELOffshrBsline5MW_InflowWind_12mps.dat'], InflowWind_Folder);


end

