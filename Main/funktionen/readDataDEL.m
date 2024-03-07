function [DELDataGruppe,Channelgruppen,FileNameStr, BaselineIndex] = readDataDEL(SimRunFolderPath, idx, BaselineCase, Channelgruppen, Optimization, readBaselineData)
%READDATADEL Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);
 z = idx;

AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
ExcelFileName = 'Analyse_DELs.xls';
filename = [AnlyseFolderPath filesep ExcelFileName];
sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
BaselineCaseStatus = "Fslse";


% Einlesen der Daten 
Data = readcell(filename);
SizeData = size(Data);
% Anzahl der Files
if SizeData(2) <= 4
    NumFiles = SizeData(2) - 3;
    % File Namen extrahieren
    FileNames = char(Data(SizeData(1) - (NumFiles-1) : end , 1));
    FileNames = FileNames(:, 7 : end);
    
    % Extrhieren der DEL-Daten      
    DELData = Data(4: SizeData(1) - NumFiles -1, 4 : end);
    % Channelnamen extrahiren
    Channelnames = string(Data(4 : SizeData(1) - NumFiles -1 ,1));
else
    NumFiles = SizeData(2) - 4;   
    % File Namen extrahieren
    FileNames = char(Data(SizeData(1) - (NumFiles-1) : end , 1));
    FileNames = FileNames(:, 8 : end);
    
    % Extrhieren der DEL-Daten      
    DELData = Data(4: SizeData(1) - NumFiles -2, 5 : end);
    % Channelnamen extrahiren
    Channelnames = string(Data(4 : SizeData(1) - NumFiles -2 ,1));
end





if (Optimization == "false") || (Optimization == "true" && readBaselineData == "true")
    
    % Pruefen, ob BaselineCase in Excel-Datei enthalten ist
    for i = 1 : NumFiles
      
        FileNameX = strtrim(FileNames(i,:));                   % String-Array mit File-Namen    
        FileNameX = FileNameX(1:end-4);        
        FileNameStr(i) = string(FileNameX);
        
        if FileNameStr(i) == BaselineCase && BaselineCaseStatus == "Fslse"
            BaselineCaseStatus = "True";
            BaselineIndex = i;
            fprintf('Der Referenzfall wurde gefunden.\n');
        end        
    end

    if BaselineCaseStatus == "Fslse"
        fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
        BaselineIndex = [];
        DELDataGruppe = [];
        Channelgruppen = [];
        return;
    end
    
else
    % Pruefen, ob BaselineCase in Excel-Datei enthalten ist
    for i = 1 : NumFiles
        FileNameX = strtrim(FileNames(i,:));                   % String-Array mit File-Namen    
        FileNameX = FileNameX(1:end-4);        
        FileNameStr(i) = string(FileNameX);       
    end
    BaselineIndex = [];
end        
       
             
% Tests durchführen
for i = 1 : length(Channelgruppen)
    % Pruefen, ob Channelgruppen in Channelnames enthalten sind
    Channelgruppen = DELChannelgruppenMemberTest(Channelgruppen,FileNameStr,Channelnames,i);
    % Extrhieren der DEL-Daten für die Channelgruppen
    if Channelgruppen(i).MemberTest == "Passed"
        % Zuordnen der DELs zu den Channels
        [~,Locb] = ismember(Channelgruppen(i).Gruppe,Channelnames);
        DELDataGruppe(i).DELs = DELData(Locb,:);
        % Pruefen, ob in den DEL-Daten wirklich nur Zahlen stehen und kein inf
        Channelgruppen = DELNumTest(DELDataGruppe(i).DELs,Channelgruppen,FileNameStr,i);                                             
    end              
end
                               

end

