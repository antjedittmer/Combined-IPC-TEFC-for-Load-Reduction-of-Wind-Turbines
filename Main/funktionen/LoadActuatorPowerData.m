function [Data] = LoadActuatorPowerData(SimRunFolderPath, idx, BaselineCase, Optimization, readBaselineData, StartTime)
%LOADACTUATORPOWERDATA Summary of this function goes here
%   Detailed explanation goes here

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
                    BaselineCasePowerDataFileNameRef = strcat('Pitch_Actuator_Power',BaselineCaseCharArray(15:end),'.mat');
                   if strcmp(AnlyseFolderFiles(ii).name, BaselineCasePowerDataFileNameRef) && BaselineCaseStatus == "False"
                       BaselineCaseStatus = "True";
                       BaselineCasePowerDataFileName = AnlyseFolderFiles(ii).name;
                       fprintf('Der Referenzfall wurde gefunden.\n');                   
                   end
                   
                   if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"Pitch_Actuator_Power") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
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
                PichActuatorPower = 0;
                if exist('PowerDataFileNames','var')                             
                    for iii = 1 : length(PowerDataFileNames)
                        load([AnlyseFolderPath filesep convertStringsToChars(PowerDataFileNames(iii,1))], 'PichActuatorPower');
                        DataTabel = array2table(PichActuatorPower(:,2:end),'VariableNames',{strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_1'), strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_2'), strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_3')});
                        Data = [Data,DataTabel];  
                        clear DataTabel
                    end
                end
                
                % Einlesen des Baselinecase
                load([AnlyseFolderPath filesep BaselineCasePowerDataFileName], 'PichActuatorPower');
                DataTabel = array2table(PichActuatorPower(:,2:end),'VariableNames',{strcat(BaselineCasePowerDataFileName,'_1'), strcat(BaselineCasePowerDataFileName,'_2'), strcat(BaselineCasePowerDataFileName,'_3')});
                Time      = PichActuatorPower(:,1);
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
                            BaselineCasePowerDataFileNameRef = strcat('Pitch_Actuator_Power',BaselineCaseCharArray(15:end),'.mat');
                           if strcmp(AnlyseFolderFiles(ii).name, BaselineCasePowerDataFileNameRef) && BaselineCaseStatus == "False"
                               BaselineCaseStatus = "True";
                               BaselineCasePowerDataFileName = AnlyseFolderFiles(ii).name;
                               fprintf('Der Referenzfall wurde gefunden.\n');                   
                           end

                           if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"Pitch_Actuator_Power") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
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
                            PichActuatorPower = 0;


                        % Einlesen des Baselinecase
                        load([AnlyseFolderPath filesep BaselineCasePowerDataFileName], 'PichActuatorPower');
                        DataTabel = array2table(PichActuatorPower(:,2:end),'VariableNames',{strcat(BaselineCasePowerDataFileName,'_1'), strcat(BaselineCasePowerDataFileName,'_2'), strcat(BaselineCasePowerDataFileName,'_3')});
                        Time      = PichActuatorPower(:,1);
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
                           if contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),"Pitch_Actuator_Power") == 1 && contains(convertCharsToStrings(AnlyseFolderFiles(ii).name),extractAfter(BaselineCase,"5MW_Land.SFunc")) == 0
                               PowerDataFileNames(k,1) = convertCharsToStrings(AnlyseFolderFiles(ii).name);
                               k = k + 1;
                           end                   
                        end 
                        
                        if exist('PowerDataFileNames','var')                             
                            % Einlesen der Daten 
                            Data = table;
                            PichActuatorPower = 0;
                            for iii = 1 : length(PowerDataFileNames)
                                load([AnlyseFolderPath filesep convertStringsToChars(PowerDataFileNames(iii,1))], 'PichActuatorPower');
                                DataTabel = array2table(PichActuatorPower(:,2:end),'VariableNames',{strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_1'), strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_2'), strcat(convertStringsToChars(PowerDataFileNames(iii,1)),'_3')});
                                Data = [Data,DataTabel];  
                                clear DataTabel
                            end
                        end
                        Time = PichActuatorPower(:,1);
                        
                        % Daten vor StartTime löschen
                        deltaT = Time(2) - Time(1);
                        Timeidx = floor(StartTime / deltaT);
                        Data(1:Timeidx,:) = [];

                end
                       
    end

end

