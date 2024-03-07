function [AnalyseDELout] = AnalyseDEL_2_max(SimRunFolderPath,BaselineCase,Channelgruppen,BaselineCaseFolderPath,DoOptimization)
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
 
 % Wenn Optimisiert wird, pruefen, ob Ordnernamen in SimRunFolderPath und
 % BaselineCaseFolderPath gleich sind
 if DoOptimization == "true"
     folderNamesBaselineCase = dir(BaselineCaseFolderPath);
     if size(folderNames,1) ~= size(folderNamesBaselineCase,1)
         fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
         AnalyseDELout = [];
         return;
     end
     
     for x = LoopStart : length(folderNames)
         if folderNames(x).name ~= folderNamesBaselineCase(x).name
             fprintf('Die Ordnernamen für die Windtestfälle in dem aktuellen Simulationsordner passen nicht zu dem Baselinecase.\n');
             AnalyseDELout = [];
             return;
         end
     end
 end
 

  for z = LoopStart : length(folderNames)                                           % loop über Windtestfälle
      switch DoOptimization
         case "false"
             % Daten einlesen
             readBaselineData = 'false';
             [DELDataGruppe,Channelgruppen,FileNameStr, BaselineIndex] = readDataDEL(SimRunFolderPath, z, BaselineCase, Channelgruppen, DoOptimization, readBaselineData);

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
             
            assignin('base','ChannelgruppenNeu', Channelgruppen);
            
             for i = 1 : length(Channelgruppen)
                 if Channelgruppen(i).MemberTest == "Passed"
                     if Channelgruppen(i).NumTest == "Passed"
                         % Mittelwerte der DELs einer Gruppe Berechnen
                         DELmax = max(cell2mat(DELDataGruppe(i).DELs),[],1);
                         
                         % Relative Aenderung des Mittelwerts im Vergleich zum
                         % Baselinecase berechnen

                         for t = 1 : length(DELmax)
                             rel_delta_max(t) = 100*(DELmax(t) - DELmax(BaselineIndex)) ./ DELmax(BaselineIndex); 
                         end        
                         Channelgruppen(i).results.RelDeltaMax = rel_delta_max;
                         Channelgruppen(i).DELs = cell2mat(DELDataGruppe(i).DELs);
                         
                        for k = 1 : length(Channelgruppen(i).Gruppe)
                           fprintf(' %s ',Channelgruppen(i).Gruppe(k));
                        end
                        fprintf('|');
                        for e = 1 : length(rel_delta_max)
                            fprintf('             %.2f %%            | ',rel_delta_max(e));
                        end
                        fprintf('\n'); 
                         
                     end
                 end
                 
                          
             end
             
          case "true"
             % Daten einlesen
             readBaselineData = 'true';
             [DELDataGruppeBaseline, ~, ~, ~] = readDataDEL(BaselineCaseFolderPath, z, BaselineCase, Channelgruppen, DoOptimization, readBaselineData);
             readBaselineData = 'false';
             [DELDataGruppe,Channelgruppen,FileNameStr, ~] = readDataDEL(SimRunFolderPath, z, BaselineCase, Channelgruppen, DoOptimization, readBaselineData);
             
             % Augabe der Ergebnisse einleiten
            fprintf('\n---------------------------------------------------------\n');
            fprintf('Simulationsordner: %s \n', folderNames(z).folder);
            fprintf('Baselinecase-Ordner: %s \n', folderNamesBaselineCase(z).folder);
            fprintf('Windtestfall: %s \n', folderNames(z).name);
            
            fprintf('Der Referenzfall ist: %s\n', BaselineCase);
            fprintf('Relative Änderungen des Mittelwerts der DELs im Vergleich zum Referenzfall %s:\n', BaselineCase);


            fprintf('Channels                      ');
            for u = 1 : length(FileNameStr)
               fprintf('| %s ', FileNameStr(u));
            end
            fprintf('|\n');
             
             for i = 1 : length(Channelgruppen)
                 if Channelgruppen(i).MemberTest == "Passed"
                     if Channelgruppen(i).NumTest == "Passed"
                         % Mittelwerte der DELs einer Gruppe Berechnen
                         DELmax = max(cell2mat(DELDataGruppe(i).DELs),[],1);
                         DELMaxBaseline = max(cell2mat(DELDataGruppeBaseline(i).DELs),[],1);

                         % Relative Aenderung des Mittelwerts im Vergleich zum
                         % Baselinecase berechnen                    
                         rel_delta_max = 100*(DELmax - DELMaxBaseline) ./ DELMaxBaseline; 

                         Channelgruppen(i).results.RelDeltaMax = rel_delta_max; 
                         Channelgruppen(i).DELs = cell2mat(DELDataGruppe(i).DELs);
                         
                         
                         for k = 1 : length(Channelgruppen(i).Gruppe)
                           fprintf(' %s ',Channelgruppen(i).Gruppe(k));
                        end
                        fprintf('|');
                        for e = 1 : length(rel_delta_max)
                            fprintf('             %.2f %%            | ',rel_delta_max(e));
                        end
                        fprintf('\n');   
                     end
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

    T = splitvars(T,"results",'NewVariableNames',["results"]);
    
    % Ergebnisse in Excel-Datei schreiben
    %writetable(T,filename,'Sheet',2,'Range','A1')
     
    % Erstellen des Outputs
    AnalyseDELout.(sprintf('%s',folderNames(z).name)) = T;
    
    % Speicher der Ergebnisse als .mat-Datei
    DELAnalyseResults.(sprintf('%s',folderNames(z).name)) = T; 
    save([SimRunFolderPath filesep folderNames(z).name filesep 'DELAnalyseResults.mat'], 'DELAnalyseResults');
    clear DELAnalyseResults
    
  end
  
  
end

