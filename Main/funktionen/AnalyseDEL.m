function [AnalyseDELout] = AnalyseDEL(SimRunFolderPath,BaselineCase,Channelgruppen)
%ANALYSEDEL Summary of this function goes here
%   Detailed explanation goes here

folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################');
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------');
 fprintf('------------------------------------------------------------\n');
 fprintf('Weiteres Post-Processing wird durchgeführt. \n');
 fprintf('DEL-Analyse wird durchgeführt. \n');
 
 
if isfile(fullfile(SimRunFolderPath,'Log.text')) == 1
    LoopStart = 4;
else
    LoopStart = 3;
end
 

  for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
    AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
    ExcelFileName = 'Analyse_DELs.xls';
    filename = [AnlyseFolderPath filesep ExcelFileName];
    sheets = sheetnames([AnlyseFolderPath filesep ExcelFileName]);
    BaselineCaseStatus = "Fslse";

      
    % Einlesen der Daten 
    Data = readcell(filename);
    SizeData = size(Data);
    
    NumFiles = SizeData(2) - 4;                                            % Anzahl der Files
    
    % File Namen extrahieren
    FileNames = char(Data(SizeData(1) - (NumFiles-1) : end , 1));
    FileNames = FileNames(:, 8 : end);
        
    for i = 1 : NumFiles
        FileNameX = strtrim(FileNames(i,:));                   % String-Array mit File-Namen    
        FileNameX = FileNameX(1:end-4);        
        FileNameStr(i) = string(FileNameX);
        % Pruefen, ob BaselineCase in Excel-Datei enthalten ist
        if FileNameStr(i) == BaselineCase && BaselineCaseStatus == "Fslse"
            BaselineCaseStatus = "True";
            BaselineIndex = i;
            fprintf('Der Referenzfall wurde gefunden.\n');
        end        
    end
    
    if BaselineCaseStatus == "Fslse"
        fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
        AnalyseDELout = [];
        return;
    end
    
    % Extrhieren der DEL-Daten      
    %DELData = cell2mat(Data(4: SizeData(1) - NumFiles -2, 5 : end))
    DELData = Data(4: SizeData(1) - NumFiles -2, 5 : end);
    
    % Pruefen, ob in den DEL-Daten wirklich nur Zahlen stehen und kein inf
    
    % Channelnamen extrahiren
    Channelnames = string(Data(4 : SizeData(1) - NumFiles -2 ,1));
    
    
    % Augabe der Ergebnisse einleiten
    fprintf('\n---------------------------------------------------------\n');
    fprintf('Simulationsordner: %s \n', folderNames(z).folder);
    fprintf('Windtestfall: %s \n', folderNames(z).name);

    fprintf('Der Referenzfall ist: %s\n', BaselineCase);
    fprintf('Relative Änderungen des Mittelwerts der DELs im Vergleich zum Referenzfall %s:\n', BaselineCase);


    fprintf('Channels                      ');
    for u = 1 : length(FileNameStr)
       fprintf('| %s ', FileNameStr(u));
    end
    fprintf('|\n');
       
    % Pruefen, ob Channelgruppen in Channelnames enthalten sind
    for i = 1 : length(Channelgruppen)
        Channelgruppen(i).Filenames = FileNameStr;
        MemberTest = ismember(Channelgruppen(i).Gruppe,Channelnames);
        if sum(MemberTest) ~= length(Channelgruppen(i).Gruppe)
            fprintf('Die Gruppe [');
            for k = 1 : length(Channelgruppen(i).Gruppe)
               fprintf(' %s ',Channelgruppen(i).Gruppe(k));
            end
            fprintf('] wurde nicht, oder nur Teilweise in den Eingelesenen Daten gefunden.\n');
            Channelgruppen(i).MemberTest = "Fail";
            %Channelgruppen(i).results.RelDeltaMean = "Nicht Berechnet";
            for u = 1 : length(FileNameStr)
                str(u) = "Nicht Berechnet";
            end
            Channelgruppen(i).results.RelDeltaMean = str;
        else
            Channelgruppen(i).MemberTest = "Passed";
        end
        
        % Extrhieren der DEL-Daten für die Channelgruppen
        if Channelgruppen(i).MemberTest == "Passed"
            % Zuordnen der DELs zu den Channels
            [~,Locb] = ismember(Channelgruppen(i).Gruppe,Channelnames);
            
            
            % Pruefen, ob in den DEL-Daten wirklich nur Zahlen stehen und kein inf
            DELDataGruppe = DELData(Locb,:);
            IsNum = cellfun('isclass', DELDataGruppe, 'double');
            DimIsNum = size(IsNum);
            if sum(IsNum, 'all') ~= (DimIsNum(1)*DimIsNum(2))
               fprintf('Die Eingelesenen DEL-Daten der Channels');
               for r = 1 : length(Channelgruppen(i).Gruppe)
                    fprintf(' %s ',Channelgruppen(i).Gruppe(r));
               end
               fprintf('sind Teilweise oder vollständig nicht numerisch.\n'); 
               Channelgruppen(i).NumTest = "Fail";
               for u = 1 : length(FileNameStr)
                   str(u) = "Nicht Berechnet";
               end
               Channelgruppen(i).results.RelDeltaMean = str;
            else
               Channelgruppen(i).NumTest = "Passed";
            end
            
            if Channelgruppen(i).NumTest == "Passed"
            
                % Mittelwerte der DELs einer Gruppe Berechnen
                DELMean = mean(cell2mat(DELDataGruppe),1);

                % Relative Aenderung des Mittelwerts im Vergleich zum
                % Baselinecase berechnen
                if (length(FileNameStr) >= 2) && (BaselineCaseStatus == "True")
                    for t = 1 : length(DELMean)
                        rel_delta_mean(t) = 100*(DELMean(t) - DELMean(BaselineIndex)) ./ DELMean(BaselineIndex); 
                    end 
                    Channelgruppen(i).results.RelDeltaMean = rel_delta_mean;
                end


                for k = 1 : length(Channelgruppen(i).Gruppe)
                   fprintf(' %s ',Channelgruppen(i).Gruppe(k));
                end
                fprintf('|');
                for e = 1 : length(rel_delta_mean)
                    fprintf('             %.2f %%            | ',rel_delta_mean(e));
                end
                fprintf('\n');
            
            end
        end 
        
          
    end 

    % Zusammenfassen der Ergebnisse in Table
    T = struct2table(Channelgruppen);
    T.results = [];    
    for n = 1 : length(Channelgruppen)
        %res(n) = Channelgruppen(n).results; 
        T.results(n) = Channelgruppen(n).results; 
    end
    %resT = struct2table(res);
    %resT = res
    %T.results = resT;   
    %T.results
    T = splitvars(T,"results",'NewVariableNames',["results"]);
    
    % Ergebnisse in Excel-Datei schreiben
    writetable(T,filename,'Sheet',2,'Range','A1')
     
    % Erstellen des Outputs
    AnalyseDELout.(sprintf('%s',folderNames(z).name)) = T;
    
  end
  
  
end

