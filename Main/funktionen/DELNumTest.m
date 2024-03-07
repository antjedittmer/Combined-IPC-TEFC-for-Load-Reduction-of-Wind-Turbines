function [Channelgruppen] = DELNumTest(DELDataGruppe,Channelgruppen,FileNameStr,i)
%DELNUMTEST Summary of this function goes here
%   Detailed explanation goes here
% Pruefen, ob in den DEL-Daten wirklich nur Zahlen stehen und kein inf
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
end

