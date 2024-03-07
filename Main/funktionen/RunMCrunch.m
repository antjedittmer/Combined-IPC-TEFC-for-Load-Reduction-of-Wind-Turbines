function [] = RunMCrunch(SimRunFolderPath, MCrunch_InputFilePath, mainFolderPath, UserInputs)
%RUMMCRUNCH Summary of this function goes here
%   Detailed explanation goes here

 folderNames = dir(SimRunFolderPath);                                      % Liste der Unterordner im Sim-Run erstellen
 fprintf('############################################################\n');
 fprintf('------------------------------------------------------------\n');
 fprintf('MCrunch wird isgesamt %d mal ausgeführt. \n', length(folderNames)-2);
 
 for z = 3 : length(folderNames)                                           % loop über Windtestfälle
     AnlyseFolderPath = [folderNames(z).folder filesep folderNames(z).name];
     copyfile(MCrunch_InputFilePath, AnlyseFolderPath);
     
     % MCrunch Inputfile an die im analyse-Ordner vorhandenen Datein
     % anpassen
     if (length(folderNames)-2) ~= length(UserInputs.MeanWindspeed)
         fprintf('\n Die Anzahl der Winddatein stimmt nicht mit der Anzahl der angegebenen mitleren Windgeshwindigkeiten überein.\n');
         return;
     end
     MeanWind = flip(UserInputs.MeanWindspeed);
     Edit_MCrunchInputFile(AnlyseFolderPath, MCrunch_InputFilePath, MeanWind(z-2));
     
     % MCrunch ausführen
     
     cd(AnlyseFolderPath);
     fprintf('------------------------------------------------------------\n');
     fprintf('MCrunch Ausführung Nr. %d von %d \n', z-2, length(folderNames)-2);
     fprintf('MCrunch wird gestartet: %s \n', datetime);
     tic 
     MCrunch('Analyse.mcru');     
     MCrunch_dauer = seconds(toc);
     MCrunch_dauer.Format = 'hh:mm:ss';
     fprintf('MCrunch Beendet.\n');
     fprintf('Benötigte Zeit zum Ausführen von MCrunch: %s \n', MCrunch_dauer);
     fprintf('------------------------------------------------------------\n');
     cd(mainFolderPath);
     
     % Fenster schließen
     figKeep1 = findall(0,'type','figure','Name','Optimization Plot Function');             % Dieses Fenster offen lassen
     figKeep2 = findall(0,'type','figure','Name','MainScopeSimulink');                      % Dieses Fenster offen lassen
     figAll   = findall(0,'type','figure');      
     figColse = setdiff(figAll, figKeep1);
     figColse = setdiff(figColse, figKeep2);     
     close(figColse)
     
     
 end

end

