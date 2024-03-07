function [pks, locs, intPSD] = ExtractPSD(ArchivFolderPath, ExcelFileName, SheetName)
%ANALYSEPSD Summary of this function goes here
%   Analyse der Leistungsdichtespektren

% Einlesen der Daten 
filename = [ArchivFolderPath filesep ExcelFileName];
PSD_Data_raw = xlsread(filename, SheetName);
PSD_Data = PSD_Data_raw(:,1:2);

% Suchen der Stellen P1 P2 und P3   
[pks, locs] = find_P(PSD_Data);

% Integrieren des Leistungsdichtepecktrums
intPSD = trapz(PSD_Data(:, 2));

%% Plotten der Leistungsdichtesprktren
PSDfig = figure; 
semilogy(PSD_Data(:, 1), PSD_Data(:, 2),...
         locs, pks, 'r-*');
grid on
xlim([0 1]);
title('Leistungsdichtespektrum');
xlabel('Frequenz [Hz]');
SheetNameLegend = strrep(SheetName,'_','\_');
legend({SheetNameLegend,'Extrema'});

savefig([ArchivFolderPath filesep convertStringsToChars(SheetName) '.fig']);
close(PSDfig)

%% Funktionen
    function [pks, locs ] = find_P(PSD_Data)
    % Suchen der lokalen Maxima
    [pks,locs] = findpeaks(PSD_Data(:,2),PSD_Data(:,1),'MinPeakDistance',0.15);
    % Wertepare für P1 P2 P3 extrahiren
    pks = pks(2:4);
    locs = locs(2:4);
    end

%     function [pks, locs ] = find_P(PSD_Data)        
%         for x = 1 : 3
%             if x == 1
%                 p = 0.2;
%             end
%             if x == 2
%                 p = 0.4;
%             end
%             if x == 3
%                 p = 0.6;
%             end
%             
%             % finde alle lokalen Maxima und Minima
%             localmax = islocalmax(PSD_Data(:, 2));
%             localmin = islocalmin(PSD_Data(:, 2));
%             
%             localmax2 = PSD_Data(localmax, 2);
%             localmin2 = PSD_Data(localmin, 2);
%             
%             % finde die Indexe an dennen die Extrema vorkommen
%             [~,LocbMax] = ismember(localmax2,PSD_Data(:, 2));
%             [~,LocbMin] = ismember(localmin2,PSD_Data(:, 2));
%             
%             
%             k = find(LocbMax);
%             j = find(LocbMin);
%             
%             % Frequenzen an dennen die Extrema vorkommen
%             F_max = PSD_Data(LocbMax(k), 1);
%             F_min = PSD_Data(LocbMin(j), 1);
%             
%             
%             [~,closestIndexMax] = min(abs(F_max-p));
%             [~,closestIndexMin] = min(abs(F_min-p));
%             
%             % Frequenzen der Maxima die am nächsten an P sind
%             F_max_closest = F_max(closestIndexMax);
%             F_min_closest = F_min(closestIndexMin);
%             
%             [~,F_closest_idx] = min([abs(F_max_closest-p) abs(F_min_closest-p)]);
%             
%             if F_closest_idx == 1
%                 F_closest = F_max_closest;
%             elseif F_closest_idx == 2
%                 F_closest = F_min_closest;
%             end
%             
%             [~,closestIndex] = ismember(F_closest,PSD_Data(:, 1));
%                        
%             pks(x)  = PSD_Data(closestIndex, 2);
%             locs(x) = PSD_Data(closestIndex, 1); 
%                          
%         end
%     end



end

