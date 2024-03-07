function [CostsOut] = CostFunctionDEL(AnalysePSDout,AnalyseStatsout,AnalyseDELout,Testcase)
%COSTFUNCTIONDEL Summary of this function goes here
%   Detailed explanation goes here

% Extrahiren der Namen der Ordner
Fieldnames1 = string(fieldnames(AnalyseStatsout));
Fieldnames2 = string(fieldnames(AnalyseStatsout.(sprintf('%s',Fieldnames1(1)))));

% Index des Testcases extrahieren
sheets = AnalyseStatsout.(sprintf('%s',Fieldnames1(1))).(sprintf('%s',Fieldnames2(1))).sheets;

TestcaseIndex = 0;
for i = 1 : length(sheets)
   if sheets(i) == Testcase
       TestcaseIndex = i;
   end    
end
if TestcaseIndex == 0
    fprintf('Der Testcase, für den die Kostenfunktion ausgewertet werden soll, wurde in den Eingelesenen Daten nicht gefunden.\n');
    CostsOut = [];
    return;
end

% Zum extrahieren der DEL-Ergebnisse
IndexChannelgruppe = 2;   % 2 weil überprüft werden soll ob DELs für RootMyc berechnet wurden

for i = 1 : length(fieldnames(AnalyseStatsout))                            % Loop ueber Windtestfaelle
        
    % Puefen, ob Werte berechnet wurden
    DELresults = AnalyseDELout.(sprintf('%s',Fieldnames1(i))).results(IndexChannelgruppe,1).RelDeltaMax(TestcaseIndex);
    if isstring(DELresults)
        fprintf('Es wurden in der DEL-Analyse keine Ergebnisse für die Ausgewählte Channelgruppe berechnet.\n');
        CostsOut = [];
        return;
    end
    
    % Kostenfunktion Auswerten
    Costs(i) = DELresults;

end

% Ausgabe der Ergebnisse 

fprintf('############################################################');
fprintf('############################################################\n');
fprintf('------------------------------------------------------------');
fprintf('------------------------------------------------------------\n');

fprintf('Auswertung der Kostenfunktion\n');
fprintf('Testcase = %s\n',Testcase);
fprintf('----------------');
for j = 1 : length(fieldnames(AnalyseStatsout))
    fprintf('| %s ', Fieldnames1(j));
end
fprintf('|\n');
fprintf('Kostenfunktion |');
for k = 1 : length(Costs)
    fprintf('     %f     |',Costs(k));
end

% Wenn es mehrere Windtestfälle gibt
if length(fieldnames(AnalyseStatsout)) > 1    
    % Die Gesamtkosten als Mittelwert aus den Einzelkosten bestimmen
    CostsOut = sum(Costs)/length(Costs);
    fprintf('\nMittelwert der Einzelkosten = %f \n', CostsOut);    
else
    CostsOut = Costs;
end


end

