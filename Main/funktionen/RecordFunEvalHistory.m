function [] = RecordFunEvalHistory(CostsOut, SimConfig, UserInputs)
%RECORDFUNEVALHISTORY Summary of this function goes here
%   Detailed explanation goes here

global history

date         = datetime;
date.Format  = 'dd.MMM.yy';
time         = datetime;
time.Format  = 'HH:mm'; 

% Zählen der Anzahl der Funktionsauswertungen
if height(history) == 0
    funccount = 1;
else
    funccount = table2array(history(height(history), 10)) + 1;
end

% Zählen der Anzahl der Iterationen
if height(history) == 0
    iteration = 0;
elseif height(history)>=2 && table2array(history(height(history), 10)) == table2array(history(height(history)-1, 10))
    iteration = table2array(history(height(history), 9)) + 1;
else
    iteration = table2array(history(height(history), 9));
end



switch UserInputs.Optimization.Function
    case "fminsearch"
        sz = [0 12];
        varNames = {'Date','Time','IPC_KP','IPC_KI','IPC_KD','TEF_KP','TEF_KI','TEF_KD','Iteration','Func-count','funValue','Procedure'};
        varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','string'};
        DataTableFunEval = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
        
        DataTableFunEval(1,:) = {date,...
                                 time,...
                                 SimConfig.controller.IPC.K_P,...
                                 SimConfig.controller.IPC.K_I,...
                                 SimConfig.controller.IPC.K_D,...
                                 SimConfig.controller.TEF.K_P,...
                                 SimConfig.controller.TEF.K_I,...
                                 SimConfig.controller.TEF.K_D,...
                                 iteration,...
                                 funccount,...
                                 CostsOut,...
                                 ""};

        % Update globale history Tabelle 
        history = [history; DataTableFunEval]; 
        
              
    case "fmincon"            
        sz = [0 15];
        varNames = {'Date',...
                  'Time',...
                  'IPC_KP',...
                  'IPC_KI',...
                  'IPC_KD',...
                  'TEF_KP',...
                  'TEF_KI',...
                  'TEF_KD',...
                  'Iteration',...
                  'Func-count',...
                  'funValue',...
                  'First-order optimality',...
                  'Current gradient of objective function',... 
                  'Current step size (displacement in x)',... 
                  'Radius of trust region'};
        varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','cell','cell','cell','cell'};         
        DataTableFunEval = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

        DataTableFunEval(1,:) = {date,...
                                 time,...
                                 SimConfig.controller.IPC.K_P,...
                                 SimConfig.controller.IPC.K_I,...
                                 SimConfig.controller.IPC.K_D,...
                                 SimConfig.controller.TEF.K_P,...
                                 SimConfig.controller.TEF.K_I,...
                                 SimConfig.controller.TEF.K_D,...
                                 iteration,...
                                 funccount,...
                                 CostsOut,...
                                 {},...
                                 {},...
                                 {},...
                                 {}}; 

        % Update globale history Tabelle                     
        history = [history; DataTableFunEval];
end

end

