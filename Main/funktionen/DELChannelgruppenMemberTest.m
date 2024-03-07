function [Channelgruppen] = DELChannelgruppenMemberTest(Channelgruppen,FileNameStr,Channelnames,i)
%DELCHANNELGRUPPENMEMBERTEST Summary of this function goes here
%   Detailed explanation goes here
    % Pruefen, ob Channelgruppen in Channelnames enthalten sind
    %for i = 1 : length(Channelgruppen)
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
    %end
end

