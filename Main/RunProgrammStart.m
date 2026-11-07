
%[16:2:24,25];  

windfilesAll = fullfile("WindData","Eigene_Wind_Dateien");                   % Nicht ändern!
PfadA = "TurbKlasseA";
PfadA1 = "TurbKlasseAnewSeed";
% PfadB = "";
PfadC = "ohneTurbulenz";

WindfilePfadA = fullfile(windfilesAll,PfadA);
WindfilePfadA1 = fullfile(windfilesAll,PfadA1); % Nicht ändern!
WindfilePfadB = windfilesAll; % Nicht ändern!
WindfilePfadC = fullfile(windfilesAll,PfadC); % Nicht ändern!

WindfileTest = WindfilePfadA;

for idx = [16,18] %[16:2:24,25]

if idx == 16
IPC.K_P = 0.354; IPC.K_I = 1.194213; IPC.K_I = 0;
TEF.K_P = 0.631; TEF.K_I = 0; TEF.K_D = 0; 
else
    IPC.K_P = 0 ; IPC.K_I = 1.5004; 1.194213;IPC.K_I = 0;
TEF.K_P =  0.45708; 0.70622; TEF.K_I = 0 ; TEF.K_D = 0;
 %0.8614     0.8826     0.08614    0.36915
 %1.5004      0       0.45708
   %     0       

end

MeanWindspeed = idx;
UserInputs_and_ProgrammStart(IPC,TEF,MeanWindspeed,WindfileTest)
end

% K_P = 0.861400 
%          K_I = 0.882600 
%          K_D = 0.086140 
%       PID-Gains TEF-Cotroller 
%          K_P = 0.369150 
%          K_I = 0.000000 
%          K_D = 0.000000 