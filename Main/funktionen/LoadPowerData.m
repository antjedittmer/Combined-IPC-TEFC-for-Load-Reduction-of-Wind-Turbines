function [Data] = LoadPowerData(SimRunFolderPath, idx, BaselineCase, Optimization, readBaselineData, Powertyp, StartTime)
%LOADPOWERDATA Summary of this function goes here
%   Detailed explanation goes here

switch Powertyp
    case "PowerElec"
        Spalte = 3;
    case "PowerRef"
        Spalte = 2;
    otherwise
        Data = [];
        return;
end

 folderNames = dir(SimRunFolderPath);
 z = idx;
    switch Optimization
            case 'false'
                AnlyseFolderPath  = [folderNames(z).folder filesep folderNames(z).name];
                AnlyseFolderFiles = dir(AnlyseFolderPath);  
                BaselineCaseStatus = "False";

                % Pruefen, ob BaselineCase in AnlyseFolderPath enthalten
                % ist und Dateinamen der vorhandenen PowerReferenceTracking-Datein
                % speichern
                T = struct2table(AnlyseFolderFiles);
                NumFiles = height(T);                
                k = 1;                
                for ii = 3 : NumFiles
                    BaselineCaseCharArray = char(BaselineCase);
                    BaselineCasePowerDataFileNameRef = strcat('PowerReferenceTracking',BaselineCaseCharArray(15:end),'.mat');
                   if strcmp(AnlyseFolderFiles(ii).name, BaselineCasePowerDataFileNameRef) && BaselineCaseStatus == "False"
                       BaselineCaseStatus = "True";
                       BaselineCasePowerDataFileName = AnlyseFolderFiles(ii).name;
                       fprintf('Der Referenzfall wurde gefunden.\n');                   
                   end
                   
                   if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"PowerReferenceTracking") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
                       PowerDataFileNames(k,1) = convertCharsToStrings(AnlyseFolderFiles(ii).name);
                       k = k + 1;
                   end                   
                end
                              
                if BaselineCaseStatus == "False"
                    fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                    Data = [];
                    return;
                end 
                 
                % Einlesen der Daten 
                Data = table;
                PowerReferenceTracking = 0;
                if exist('PowerDataFileNames','var')                             
                    for iii = 1 : length(PowerDataFileNames)
                        load([AnlyseFolderPath filesep convertStringsToChars(PowerDataFileNames(iii,1))], 'PowerReferenceTracking');
                        DataTabel = array2table(PowerReferenceTracking(:,Spalte),'VariableNames',{convertStringsToChars(PowerDataFileNames(iii,1))});
                        Data = [Data,DataTabel];  
                        clear DataTabel
                    end
                end
                
                % Einlesen des Baselinecase
                load([AnlyseFolderPath filesep BaselineCasePowerDataFileName], 'PowerReferenceTracking');
                DataTabel = array2table(PowerReferenceTracking(:,Spalte),'VariableNames',{BaselineCasePowerDataFileName});
                Time      = PowerReferenceTracking(:,1);
                Data = [DataTabel,Data];
                
                % Daten vor StartTime löschen
                deltaT = Time(2) - Time(1);
                Timeidx = floor(StartTime / deltaT);
                Data(1:Timeidx,:) = [];
                                               
            case 'true'
                switch readBaselineData
                    case 'true'   
                        AnlyseFolderPath  = [folderNames(z).folder filesep folderNames(z).name];
                        AnlyseFolderFiles = dir(AnlyseFolderPath);  
                        BaselineCaseStatus = "False";

                        % Pruefen, ob BaselineCase in AnlyseFolderPath enthalten
                        % ist und Dateinamen der vorhandenen PowerReferenceTracking-Datein
                        % speichern
                        T = struct2table(AnlyseFolderFiles);
                        NumFiles = height(T);                
                        k = 1;                
                        for ii = 3 : NumFiles
                            BaselineCaseCharArray = char(BaselineCase);
                            BaselineCasePowerDataFileNameRef = strcat('PowerReferenceTracking',BaselineCaseCharArray(15:end),'.mat');
                           if strcmp(AnlyseFolderFiles(ii).name, BaselineCasePowerDataFileNameRef) && BaselineCaseStatus == "False"
                               BaselineCaseStatus = "True";
                               BaselineCasePowerDataFileName = AnlyseFolderFiles(ii).name;
                               fprintf('Der Referenzfall wurde gefunden.\n');                   
                           end

                           if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"PowerReferenceTracking") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
                               PowerDataFileNames(k,1) = convertCharsToStrings(AnlyseFolderFiles(ii).name);
                               k = k + 1;
                           end                   
                        end

                        if BaselineCaseStatus == "False"
                            fprintf('Der Referenzfall wurde nicht in den eingelesenen Daten gefunden.\n'); 
                            Data = [];
                            return;
                        end 
                                                   
                            % Einlesen der Daten 
                            Data = table;
                            PowerReferenceTracking = 0;


                        % Einlesen des Baselinecase
                        load([AnlyseFolderPath filesep BaselineCasePowerDataFileName], 'PowerReferenceTracking');
                        DataTabel = array2table(PowerReferenceTracking(:,Spalte),'VariableNames',{BaselineCasePowerDataFileName});
                        Time      = PowerReferenceTracking(:,1);
                        Data = [DataTabel,Data];  
                        
                        % Daten vor StartTime löschen
                        deltaT = Time(2) - Time(1);
                        Timeidx = floor(StartTime / deltaT);
                        Data(1:Timeidx,:) = [];                        

                                         
                    case 'false'
                        AnlyseFolderPath  = [folderNames(z).folder filesep folderNames(z).name];
                        AnlyseFolderFiles = dir(AnlyseFolderPath);  
                        

                        % Pruefen, ob BaselineCase in AnlyseFolderPath enthalten
                        % ist und Dateinamen der vorhandenen PowerReferenceTracking-Datein
                        % speichern
                        T = struct2table(AnlyseFolderFiles);
                        NumFiles = height(T);                
                        k = 1;                
                        for ii = 3 : NumFiles
                           if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"PowerReferenceTracking") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
                               PowerDataFileNames(k,1) = convertCharsToStrings(AnlyseFolderFiles(ii).name);
                               k = k + 1;
                           end                   
                        end 
                        
                        if exist('PowerDataFileNames','var')                             
                            % Einlesen der Daten 
                            Data = table;
                            PowerReferenceTracking = 0;
                            for iii = 1 : length(PowerDataFileNames)
                                load([AnlyseFolderPath filesep convertStringsToChars(PowerDataFileNames(iii,1))], 'PowerReferenceTracking');
                                DataTabel = array2table(PowerReferenceTracking(:,Spalte),'VariableNames',{convertStringsToChars(PowerDataFileNames(iii,1))});
                                Data = [Data,DataTabel];  
                                clear DataTabel
                            end
                        end
                        Time      = PowerReferenceTracking(:,1);
                        
                        % Daten vor StartTime löschen
                        deltaT = Time(2) - Time(1);
                        Timeidx = floor(StartTime / deltaT);
                        Data(1:Timeidx,:) = [];                        
                        
                end
                       
    end


end

