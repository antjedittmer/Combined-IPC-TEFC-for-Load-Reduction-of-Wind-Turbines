clear; close all;

%% > Pfade speichern <
%    Pfad zum Main-Ordner speichern
mainFolder = pwd;
%    Pfad zum Programmordner speichern
[programm_filepath,~,~] = fileparts(pwd);


%% Angabe des MCrunch Archivs 
Location_MCrunch_Archiv_Folder = fullfile(programm_filepath,'Post_processing','MCrunch','Archiv','Archiv_1');

%% Ladern der Dateien mit den Klappenwinkeln
load([Location_MCrunch_Archiv_Folder filesep 'Flap_Angles_1.mat']);
Flap_Angles_1 = Flap_Angles;
clear Flap_Angles
load([Location_MCrunch_Archiv_Folder filesep 'Flap_Angles_2.mat']);
Flap_Angles_2 = Flap_Angles;
clear Flap_Angles

%% Erstellen der Plots
figure
plot(Flap_Angles_1(:,1), Flap_Angles_1(:,2),...
     Flap_Angles_2(:,1), Flap_Angles_2(:,2),...
     Flap_Angles_2(:,1), Flap_Angles_2(:,3),...
     Flap_Angles_2(:,1), Flap_Angles_2(:,4));
xlim([40 100]);
grid on
title('Ausschlaege der Klappen');
xlabel('Zeit [s]');
ylabel('Klappenausschlaege [grad]');
legend('mit ausgeschaltetem TEF-Regler', 'Klappe 1', 'Klappe 2', 'Klappe 3');





