function [CostsOut] = CostFunction1(AnalysePSDout,AnalyseStatsout,AnalyseDELout,Testcase)
%COSTFUNCTION1 Summary of this function goes here
%   Detailed explanation goes here
%   ostenfunktion fuer IPC on und TEF on 

% Abfragen, ob einer der Analyseoutputs Leer ist


% Extrahiren der Namen der Ordner
Fieldnames = string(fieldnames(AnalyseStatsout));

% Index des Testcases extrahieren
sheets = AnalyseStatsout.(sprintf('%s',Fieldnames(1))).sheets;
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
IndexChannelgruppe = 1;

for i = 1 : length(fieldnames(AnalyseStatsout))                            % Loop ueber Windtestfaelle
    
    StdDev = AnalyseStatsout.(sprintf('%s',Fieldnames(i))).RelDeltaStdDev(TestcaseIndex);
    Mean   = AnalyseStatsout.(sprintf('%s',Fieldnames(i))).RelDeltaMean(TestcaseIndex);
    
    IntPSD = AnalysePSDout.(sprintf('%s',Fieldnames(i))).RelDeltaInt(TestcaseIndex);
    P1     = AnalysePSDout.(sprintf('%s',Fieldnames(i))).RelDeltaP(1 ,TestcaseIndex);
    P2     = AnalysePSDout.(sprintf('%s',Fieldnames(i))).RelDeltaP(2 ,TestcaseIndex);
    P3     = AnalysePSDout.(sprintf('%s',Fieldnames(i))).RelDeltaP(3 ,TestcaseIndex);
    
    %Gruppe = AnalyseDELout.(sprintf('%s',Fieldnames(i))).Gruppe{IndexChannelgruppe,1};
    % Puefen, ob Werte berechnet wurden
    DELresults = AnalyseDELout.(sprintf('%s',Fieldnames(i))).results(IndexChannelgruppe,1).RelDeltaMean(TestcaseIndex);
    if isstring(DELresults)
        fprintf('Es wurden in der DEL-Analyse keine Ergebnisse für die Ausgewählte Channelgruppe berechnet.\n');
        CostsOut = [];
        return;
    end
    %DELresults = DELresults(TestcaseIndex);
    
    % Kostenfunktion Auswerten
    Costs(i) = StdDev + Mean + IntPSD + P1 + P2 + P3 + DELresults;

end

% Ausgabe der Ergebnisse 
CostsOut = Costs;

fprintf('############################################################');
fprintf('############################################################\n');
fprintf('------------------------------------------------------------');
fprintf('------------------------------------------------------------\n');

fprintf('Auswertung der Kostenfunktion\n');
fprintf('Testcase = %s\n',Testcase);
fprintf('----------------');
for j = 1 : length(fieldnames(AnalyseStatsout))
    fprintf('| %s ', Fieldnames(j));
end
fprintf('|\n');
fprintf('Kostenfunktion |');
for k = 1 : length(CostsOut)
    fprintf('     %f     | ',CostsOut(k));
end
 

end

