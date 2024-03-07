function [x] = fminconStart(UserInputs,fun,x0,OptimizationResultsFolderPath)
%FMINCONSTART Summary of this function goes here
%   Funktion zum Starten der Optimierung mit fmincon

% Globale Variable (Tabelle) zum aufzeichenen der
% Optimization-History initialisieren

global history

% History-Tabelle initialisieren
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
varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','double','cell','double','double'};
history = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Optionen für die Optimierung 
switch UserInputs.Optimization.StopCriteria 
    case "MaxIter"
        options = optimoptions(@fmincon,'Algorithm','interior-point',...
                               'Display','iter-detailed',...
                               'MaxIterations',UserInputs.Optimization.NumberIterations,...
                               'OutputFcn',@myoutput,...
                               'PlotFcns',@optimplotfval,...
                               'UseParallel',false,...
                               'DiffMaxChange',UserInputs.Optimization.fmincon.DiffMaxChange,...
                               'DiffMinChange',UserInputs.Optimization.fmincon.DiffMinChange);
    case "MaxFunEvals"
        options = optimoptions(@fmincon,'Algorithm','interior-point',...
                               'Display','iter-detailed',...
                               'MaxFunctionEvaluations',UserInputs.Optimization.NumberFunctionEvaluations,...
                               'OutputFcn',@myoutput,...
                               'PlotFcns',@optimplotfval,...
                               'UseParallel',false,...
                               'DiffMaxChange',UserInputs.Optimization.fmincon.DiffMaxChange,...
                               'DiffMinChange',UserInputs.Optimization.fmincon.DiffMinChange);
    otherwise
        fprintf('\nUngültige Eingabe für das Abbruchkriterium beim Optimieren.\n');
        return;
end

% Grenzen festlegen
  switch UserInputs.IPC_Controller.Typ
        case "P"
            switch UserInputs.TEF_Controller.Typ
                case "P"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4);                    
                case "I"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);                                         
                case "PI"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);
                case "PID"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(6);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);  
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(6); 
            end
        case "I"
            switch UserInputs.TEF_Controller.Typ
                case "P"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4);                    
                case "I"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);                                         
                case "PI"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);
                case "PID"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(6);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);  
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(6); 
            end                  
        case "PI"
            switch UserInputs.TEF_Controller.Typ
                case "P"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4);                    
                case "I"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);                                         
                case "PI"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);
                case "PID"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    LowerBound(5) = UserInputs.Optimization.fmincon.Constraints.LowerBound(6);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);  
                    UpperBound(5) = UserInputs.Optimization.fmincon.Constraints.UpperBound(6); 
            end                               
        case "PID"
            switch UserInputs.TEF_Controller.Typ
                case "P"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(3);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(3);
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4);                    
                case "I"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(3);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(3);
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);                                         
                case "PI"
                    LowerBound(1) = UserInputs.Optimization.fmincon.Constraints.LowerBound(1);
                    LowerBound(2) = UserInputs.Optimization.fmincon.Constraints.LowerBound(2);
                    LowerBound(3) = UserInputs.Optimization.fmincon.Constraints.LowerBound(3);
                    LowerBound(4) = UserInputs.Optimization.fmincon.Constraints.LowerBound(4);
                    LowerBound(5) = UserInputs.Optimization.fmincon.Constraints.LowerBound(5);
                    UpperBound(1) = UserInputs.Optimization.fmincon.Constraints.UpperBound(1);
                    UpperBound(2) = UserInputs.Optimization.fmincon.Constraints.UpperBound(2);
                    UpperBound(3) = UserInputs.Optimization.fmincon.Constraints.UpperBound(3);
                    UpperBound(4) = UserInputs.Optimization.fmincon.Constraints.UpperBound(4); 
                    UpperBound(5) = UserInputs.Optimization.fmincon.Constraints.UpperBound(5);
                case "PID"
                    LowerBound = UserInputs.Optimization.fmincon.Constraints.LowerBound;
                    UpperBound = UserInputs.Optimization.fmincon.Constraints.UpperBound; 
            end                       
  end

% Use TowerDELs as nonlinear constraints?
if UserInputs.Optimization.fmincon.UseNonlcon == "Yes"
    nonlconHandle = @(x)nonlcon(x,UserInputs);
else
    nonlconHandle = [];
end

% fmincon ausführen
[x,fval,exitflag,output] = fmincon(fun,x0,[],[],[],[],LowerBound,UpperBound,nonlconHandle,options);

% Nested Output Function für fmincon
    function stop = myoutput(x,optimValues,state)
        stop = false;
        if isequal(state,'iter')                    
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
          varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','double','cell','double','double'};         
          DataTableIteration = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
          date         = datetime;
          date.Format  = 'dd.MMM.yy';
          time         = datetime;
          time.Format  = 'HH:mm'; 
          
          switch UserInputs.IPC_Controller.Typ
                case "P"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0,x(2), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                            
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, 0, x(2), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, x(2), x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                          
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, x(2), x(3), x(4), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                      
                    end
                case "I"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0,x(2), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                            
                        case "I"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, 0, x(2), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, x(2), x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                          
                        case "PID"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, x(2), x(3), x(4), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                      
                    end                         
                case "PI"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0,x(3), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                            
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, 0, x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, x(3), x(4), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                          
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, x(3), x(4), x(5), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                      
                    end                          
                case "PID"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3) ,x(4), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                            
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), 0, x(4), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), x(4), x(5), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                          
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), x(4), x(5), x(6), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.firstorderopt, mat2cell(transpose(optimValues.gradient),1), optimValues.stepsize, optimValues.trustregionradius};                      
                    end                    
          end
                   
          history = [history; DataTableIteration];          
        end
        % Plots erstellen
        if isequal(state,'done')            
            %Iteration = 0 : 1 : table2array(history(height(history), 9));
            for i = 1 : height(history)          
               if i >= 2 && table2array(history(i, 10)) == table2array(history(i-1, 10)) && UserInputs.Optimization.fmincon.UseNonlcon == "No"
                    IterationFunValue(i)    = table2array(history(i, 11));
                    FunCountAtInteration(i) = table2array(history(i, 10));
                    Iteration(i)            = table2array(history(i, 9));
               elseif i >= 2 && table2array(history(i, 10))-1 ~= table2array(history(i-1, 10)) && UserInputs.Optimization.fmincon.UseNonlcon == "Yes"
                    IterationFunValue(i)    = table2array(history(i, 11));
                    FunCountAtInteration(i) = table2array(history(i, 10));
                    Iteration(i)            = table2array(history(i, 9));                                      
               else
                    IterationFunValue(i)    = NaN;
                    FunCountAtInteration(i) = NaN; 
                    Iteration(i)            = NaN;
               end                
            end
            IterationFunValue    = IterationFunValue(~isnan(IterationFunValue));
            FunCountAtInteration = FunCountAtInteration(~isnan(FunCountAtInteration));
            Iteration            = Iteration(~isnan(Iteration));
            
            %IterationFunValue
            %FunCountAtInteration
            %Iteration
            %history
            
            if length(Iteration) == length(IterationFunValue)           
                OtimPlot1 = figure; 
                plot(Iteration,IterationFunValue,'diamond','MarkerEdgeColor','k','MarkerFaceColor','m');
                title('Entwiklung der Kostenfunktiosergebnisse');
                xlabel('Iteration');
                ylabel('Wert der Kostenfunktion')
                grid on
                saveas(OtimPlot1,fullfile(OptimizationResultsFolderPath,'Iteration_Plot.fig'));
            else
                fprintf('\nDie Vektoren Iteration und IterationFunValue in der Funktion fminconStart haben nicht die selbe länge.\n');
            end
            
            if length(FunCountAtInteration) == length(IterationFunValue)  
                OtimPlot2 = figure; 
                plot(table2array(history(:,10)),history.funValue,'diamond','MarkerEdgeColor','k','MarkerFaceColor','m');
                hold on
                plot(FunCountAtInteration,IterationFunValue,'diamond','MarkerEdgeColor','k','MarkerFaceColor','g');
                hold off
                title('Entwiklung der Kostenfunktiosergebnisse');
                xlabel('Anzahl der Simulationen [-]');
                ylabel('Wert der Kostenfunktion');
                grid on
                saveas(OtimPlot2,fullfile(OptimizationResultsFolderPath,'SimCount_Plot.fig'));
            else
                fprintf('\nDie Vektoren FunCountAtInteration und IterationFunValue in der Funktion fminconStart haben nicht die selbe länge.\n');                
            end
        end     
    end


end

