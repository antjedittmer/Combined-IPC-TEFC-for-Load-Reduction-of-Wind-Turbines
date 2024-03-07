function [] = GridSearch(UserInputs)
%GRIDSEARCH Summary of this function goes here
%   Detailed explanation goes here

if UserInputs.GridSearch.MakeUnsymetricGrid ~= "Yes" && UserInputs.GridSearch.MakeUnsymetricGrid ~= "No"
        fprintf('\n Fehler! Ungültige Eingabe für MakeUnsymetricGrid. Zulässig ist Yes oder No.\n');
        return;
end


%% Baselinecase Simulieren und Analysieren
                
% Prüfen, dass nur ein Windfile verwendet wird
%UserInputs.WindDataFiles

% Simulationen und MCrunch
UserInputs.ActionCommands.MCrunch             = 'Yes';
UserInputs.ActionCommands.Simulations         = 'Yes';

% Further Post-Processing
UserInputs.Optimization.Do                               = "false";
UserInputs.FurtherPostProcessing.PSDanalyse.Do           = 'No';
UserInputs.FurtherPostProcessing.StatsAnalyse.Do         = 'No';
UserInputs.FurtherPostProcessing.DELanalyse.Do           = 'No';
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do = 'No';
UserInputs.FurtherPostProcessing.PowerAnalyse.Do         = 'No';
UserInputs.CostFunktion.Do                               = 'No';

% Basisregler einschalten
UserInputs.CPC_Controller.Switch   = 'on';
UserInputs.GenTq_Controller.Switch = 'on';

% IPC- und TEF-Regler abschalten
UserInputs.IPC_Controller.Switch = 'off';
UserInputs.TEF_Controller.Switch = 'off';

% Optimierung
UserInputs.Optimization.Do = "false";
UserInputs.Optimization.BaselineCaseFolderPath = [];

% Baselinecase erzeugen
[~, SimRunFolderPath] = main(UserInputs);


%% Opiemierung Starten
% Further Post-Processing
UserInputs.Optimization.Do                               = "true";
UserInputs.FurtherPostProcessing.PSDanalyse.Do           = 'Yes';
UserInputs.FurtherPostProcessing.StatsAnalyse.Do         = 'Yes';
UserInputs.FurtherPostProcessing.DELanalyse.Do           = 'Yes';
UserInputs.FurtherPostProcessing.ActuatorPowerAnalyse.Do = 'Yes';
UserInputs.FurtherPostProcessing.PowerAnalyse.Do         = 'Yes';
UserInputs.CostFunktion.Do                               = 'Yes';

BaselineCase = "5MW_Land.SFunc_TEF_off_IPC_off";
UserInputs.FurtherPostProcessing.PSDanalyse.BaselineCase   = BaselineCase;
UserInputs.FurtherPostProcessing.StatsAnalyse.BaselineCase = BaselineCase;
UserInputs.FurtherPostProcessing.DELanalyse.BaselineCase   = BaselineCase;

% Regler entsprechend dem gewählten Testcase einschalten        
switch UserInputs.Optimization.Testcase
    case "5MW_Land.SFunc_TEF_off_IPC_off"
        fprintf('Der gewählte Testcase entspricht dem Baselinecase. Um eine Optimierung durchzuführen muss der Testcase ein anderer als der Baselinecase sein.\n');
        return;
    case "5MW_Land.SFunc_TEF_off_IPC_on"                 
        UserInputs.IPC_Controller.Switch = 'on';
        UserInputs.TEF_Controller.Switch = 'off';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    case "5MW_Land.SFunc_TEF_on_IPC_off"                 
        UserInputs.IPC_Controller.Switch = 'off';
        UserInputs.TEF_Controller.Switch = 'on';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    case "5MW_Land.SFunc_TEF_on_IPC_on"                 
        UserInputs.IPC_Controller.Switch = 'on';
        UserInputs.TEF_Controller.Switch = 'on';
        UserInputs.CostFunktion.Testcase = UserInputs.Optimization.Testcase;
    otherwise
        fprintf('Die Eingabe für den Testcase ist ungültig. Wählen Sie eine der folgenden Möglichkeiten:\n');
        fprintf(' "5MW_Land.SFunc_TEF_off_IPC_on" \n');
        fprintf(' "5MW_Land.SFunc_TEF_on_IPC_off" \n');
        fprintf(' "5MW_Land.SFunc_TEF_on_IPC_on" \n');
        return;
end

% Den Pfad zu den Simulationsergebnisen des Baselinecase angeben
UserInputs.Optimization.BaselineCaseFolderPath = SimRunFolderPath;

% Ordner zum Speichern der Optimierungsergebnisse erstellen
t                = datetime;
t.Format         = 'dd-MMM-yy_HH-mm';
OptimizationResultsFolderName = append('GridSearch_Ergebnisse_', char(t));
mkdir('Post_processing',OptimizationResultsFolderName); 
OptimizationResultsFolderPath = fullfile(pwd,'Post_processing',OptimizationResultsFolderName);


% Grid für Reglergains definieren
IPC_KI_GridUpperBound = UserInputs.GridSearch.IPC_KI_GridUpperBound;
IPC_KI_GridLowerBound = UserInputs.GridSearch.IPC_KI_GridLowerBound;
IPC_KI_GridStep       = UserInputs.GridSearch.IPC_KI_GridStep;
TEF_KP_GridUpperBound = UserInputs.GridSearch.TEF_KP_GridUpperBound;
TEF_KP_GridLowerBound = UserInputs.GridSearch.TEF_KP_GridLowerBound;
TEF_KP_GridStep       = UserInputs.GridSearch.TEF_KP_GridStep;

IPC_KI_NPoints =(IPC_KI_GridUpperBound - IPC_KI_GridLowerBound) / IPC_KI_GridStep;
IPC_KI         = linspace(IPC_KI_GridLowerBound,IPC_KI_GridUpperBound,IPC_KI_NPoints+1);
TEF_KP_NPoints =(TEF_KP_GridUpperBound - TEF_KP_GridLowerBound) / TEF_KP_GridStep;
TEF_KP         = linspace(TEF_KP_GridLowerBound,TEF_KP_GridUpperBound,TEF_KP_NPoints+1);

[F,S] = ndgrid(IPC_KI, TEF_KP);

% Inputvektoren zusammenstellen
for i = 1 : numel(F)
    x(1) = F(i); 
    x(2) = S(i);
    M(i).f = [x(1) x(2)];    
end

fun = @(x)main(UserInputs,x.f);
GritSearchResult = arrayfun(fun, M);

clear M x

% Ergebnismatrix erstellen
[numRows,~] = size(F);
s = 1;
z = 1;
for i = 1 : numel(F)
    GritSearchResultMatrix(z,s) = GritSearchResult(i);
    z = z + 1;
    if mod(i,numRows) == 0
        s = s + 1;
        z = 1;
    end     
end


% Prüfen, ob das Grid erweitert werden soll
switch UserInputs.GridSearch.MakeUnsymetricGrid
    case "Yes"
       % Erweitertes Grid für TEF_KP erstellen und auswerten
       if UserInputs.GridSearch.TEF_KP_ExpandLowerBoundto < UserInputs.GridSearch.TEF_KP_GridLowerBound
           % Grid für Reglergains definieren
            IPC_KI_GridUpperBound = UserInputs.GridSearch.IPC_KI_GridUpperBound;
            IPC_KI_GridLowerBound = UserInputs.GridSearch.IPC_KI_GridLowerBound;
            IPC_KI_GridStep       = UserInputs.GridSearch.IPC_KI_GridStep;
            TEF_KP_GridUpperBound = UserInputs.GridSearch.TEF_KP_GridLowerBound;
            TEF_KP_GridLowerBound = UserInputs.GridSearch.TEF_KP_ExpandLowerBoundto;
            TEF_KP_GridStep       = UserInputs.GridSearch.TEF_KP_GridStep;

            IPC_KI_NPoints =(IPC_KI_GridUpperBound - IPC_KI_GridLowerBound) / IPC_KI_GridStep;
            IPC_KI         = linspace(IPC_KI_GridLowerBound,IPC_KI_GridUpperBound,IPC_KI_NPoints+1);
            TEF_KP_NPoints =(TEF_KP_GridUpperBound - TEF_KP_GridLowerBound) / TEF_KP_GridStep;
            TEF_KP         = linspace(TEF_KP_GridLowerBound,TEF_KP_GridUpperBound-TEF_KP_GridStep,TEF_KP_NPoints);

            [F_TEF_KP_Expand,S_TEF_KP_Expand] = ndgrid(IPC_KI, TEF_KP);

            % Inputvektoren zusammenstellen
            for i = 1 : numel(F_TEF_KP_Expand)
                x(1) = F_TEF_KP_Expand(i); 
                x(2) = S_TEF_KP_Expand(i);
                M_TEF_KP_Expand(i).f = [x(1) x(2)];    
            end

            fun = @(x)main(UserInputs,x.f);
            GritSearchResult_TEF_KP_Expand = arrayfun(fun, M_TEF_KP_Expand);  

            clear x

            % Ergebnismatrix erstellen
            [numRows,~] = size(F_TEF_KP_Expand);
            s = 1;
            z = 1;
            for i = 1 : numel(F_TEF_KP_Expand)
                GritSearchResultMatrix_TEF_KP_Expand(z,s) = GritSearchResult_TEF_KP_Expand(i);
                z = z + 1;
                if mod(i,numRows) == 0
                    s = s + 1;
                    z = 1;
                end     
            end

       else
           GritSearchResultMatrix_TEF_KP_Expand = [];
           F_TEF_KP_Expand = [];
           S_TEF_KP_Expand = [];        
       end

       % Erweitertes Grid für IPC_KI erstellen und auswerten
       if UserInputs.GridSearch.IPC_KI_ExpandLowerBoundto < UserInputs.GridSearch.IPC_KI_GridLowerBound
           % Grid für Reglergains definieren
            IPC_KI_GridUpperBound = UserInputs.GridSearch.IPC_KI_GridLowerBound;
            IPC_KI_GridLowerBound = UserInputs.GridSearch.IPC_KI_ExpandLowerBoundto;
            IPC_KI_GridStep       = UserInputs.GridSearch.IPC_KI_GridStep;
            TEF_KP_GridUpperBound = UserInputs.GridSearch.TEF_KP_GridUpperBound;
            TEF_KP_GridLowerBound = UserInputs.GridSearch.TEF_KP_GridLowerBound;
            TEF_KP_GridStep       = UserInputs.GridSearch.TEF_KP_GridStep;

            IPC_KI_NPoints =(IPC_KI_GridUpperBound - IPC_KI_GridLowerBound) / IPC_KI_GridStep;
            IPC_KI         = linspace(IPC_KI_GridLowerBound,IPC_KI_GridUpperBound-IPC_KI_GridStep,IPC_KI_NPoints);
            TEF_KP_NPoints =(TEF_KP_GridUpperBound - TEF_KP_GridLowerBound) / TEF_KP_GridStep;
            TEF_KP         = linspace(TEF_KP_GridLowerBound,TEF_KP_GridUpperBound,TEF_KP_NPoints+1);

            [F_IPC_KI_Expand,S_IPC_KI_Expand] = ndgrid(IPC_KI, TEF_KP);

            % Inputvektoren zusammenstellen
            for i = 1 : numel(F_IPC_KI_Expand)
                x(1) = F_IPC_KI_Expand(i); 
                x(2) = S_IPC_KI_Expand(i);
                M_IPC_KI_Expand(i).f = [x(1) x(2)];    
            end

            fun = @(x)main(UserInputs,x.f);
            GritSearchResult_IPC_KI_Expand = arrayfun(fun, M_IPC_KI_Expand); 

            clear x

            % Ergebnismatrix erstellen
            [numRows,~] = size(F_IPC_KI_Expand);
            s = 1;
            z = 1;
            for i = 1 : numel(F_IPC_KI_Expand)
                GritSearchResultMatrix_IPC_KI_Expand(z,s) = GritSearchResult_IPC_KI_Expand(i);
                z = z + 1;
                if mod(i,numRows) == 0
                    s = s + 1;
                    z = 1;
                end     
            end

       else
           GritSearchResultMatrix_IPC_KI_Expand = [];
           F_IPC_KI_Expand = [];
           S_IPC_KI_Expand = [];
       end  
   
    case "No"
       GritSearchResultMatrix_IPC_KI_Expand = [];
       F_IPC_KI_Expand = [];
       S_IPC_KI_Expand = [];
       
       GritSearchResultMatrix_TEF_KP_Expand = [];
       F_TEF_KP_Expand = [];
       S_TEF_KP_Expand = [];
       
    otherwise
        fprintf('\n Fehler! Ungültige Eingabe für MakeUnsymetricGrid. Zulässig ist Yes oder No.\n');
        return;       
end

% Speichern der GridSearch Ergebnisse als .mat-Datei
save(fullfile(OptimizationResultsFolderPath,'GridSearch_Ergebnisse.mat'),'F','S','GritSearchResultMatrix','F_IPC_KI_Expand','S_IPC_KI_Expand','GritSearchResultMatrix_IPC_KI_Expand','F_TEF_KP_Expand','S_TEF_KP_Expand','GritSearchResultMatrix_TEF_KP_Expand');

% Plot erstellen und ergebnisse speichern

GridSearchPlot = figure;
ax = gca;
ax.FontSize = 16; 
hold on
surf(F,S,GritSearchResultMatrix)
surf(F_IPC_KI_Expand,S_IPC_KI_Expand,GritSearchResultMatrix_IPC_KI_Expand)
surf(F_TEF_KP_Expand,S_TEF_KP_Expand,GritSearchResultMatrix_TEF_KP_Expand)
hold off
grid on
colormap jet
colorbar

ylabel('P-Gain (TEF)','FontSize',16,'Interpreter','latex');
xlabel('I-Gain (IPC)','FontSize',16,'Interpreter','latex');
zlabel('Kostenfunktion','FontSize',16,'Interpreter','latex');
title('Grid-Search-Ergebnisse','FontSize',16,'Interpreter','latex');
set(gca,'TickLabelInterpreter','latex');

% Plot 2
GridSearchPlot2 = figure;
ax = gca;
ax.FontSize = 16; 
hold on
surf(F,S,GritSearchResultMatrix.*(-1))
surf(F_IPC_KI_Expand,S_IPC_KI_Expand,GritSearchResultMatrix_IPC_KI_Expand.*(-1))
surf(F_TEF_KP_Expand,S_TEF_KP_Expand,GritSearchResultMatrix_TEF_KP_Expand.*(-1))
hold off
grid on
colormap jet
colorbar

ylabel('P-Gain (TEF)','FontSize',16,'Interpreter','latex');
xlabel('I-Gain (IPC)','FontSize',16,'Interpreter','latex');
zlabel('Kostenfunktion','FontSize',16,'Interpreter','latex');
title('Grid-Search-Ergebnisse','FontSize',16,'Interpreter','latex');
set(gca,'TickLabelInterpreter','latex');

%Plot speichern
saveas(GridSearchPlot,fullfile(OptimizationResultsFolderPath,'GridSearch_Plot.fig'));
saveas(GridSearchPlot,fullfile(OptimizationResultsFolderPath,'GridSearch_Plot.jpg'));

saveas(GridSearchPlot2,fullfile(OptimizationResultsFolderPath,'GridSearch_Plot2.fig'));
saveas(GridSearchPlot2,fullfile(OptimizationResultsFolderPath,'GridSearch_Plot2.jpg'));
        

end

