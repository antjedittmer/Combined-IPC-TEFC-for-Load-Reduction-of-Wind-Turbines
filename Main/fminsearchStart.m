function [x] = fminsearchStart(UserInputs,fun,x0,OptimizationResultsFolderPath)
%FMINSEARCHSTART Summary of this function goes here
%   Funktion zum Starten der Optimierung mit fminsearch

% Globale Variable (Tabelle) zum aufzeichenen der
% Optimization-History initialisieren

global history

% History-Tabelle initialisieren
sz = [0 12];
varNames = {'Date','Time','IPC_KP','IPC_KI','IPC_KD','TEF_KP','TEF_KI','TEF_KD','Iteration','Func-count','funValue','Procedure'};
varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','string'};
history = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);

% Optionen für die Optimierung
switch UserInputs.Optimization.StopCriteria
    case "MaxIter"
        options = optimset('OutputFcn',@myoutput,'PlotFcns',@optimplotfval,'Display','iter','MaxIter',UserInputs.Optimization.NumberIterations);
    case "MaxFunEvals"
        options = optimset('OutputFcn',@myoutput,'PlotFcns',@optimplotfval,'Display','iter','MaxFunEvals',UserInputs.Optimization.NumberFunctionEvaluations);
    otherwise
        fprintf('\nUngültige Eingabe für das Abbruchkriterium beim Optimieren.\n');
        return;
end

% fminsearch ausführen

[x,fval,exitflag,output] = fminsearch(fun,x0,options);

% Nested Output Function für fminsearch
    function stop = myoutput(x,optimValues,state)
        stop = false;
        if isequal(state,'iter')
            sz = [0 12];
            varNames = {'Date','Time','IPC_KP','IPC_KI','IPC_KD','TEF_KP','TEF_KI','TEF_KD','Iteration','Func-count','funValue','Procedure'};
            varTypes = {'string','string','double','double','double','double','double','double','int64','int64','double','string'};
            DataTableIteration = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
            date         = datetime;
            date.Format  = 'dd.MMM.yy';
            time         = datetime;
            time.Format  = 'HH:mm';

            switch UserInputs.IPC_Controller.Typ
                case "P"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0,x(2), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, 0, x(2), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, x(2), x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), 0, 0, x(2), x(3), x(4), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                    end
                case "I"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0,x(2), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "I"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, 0, x(2), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, x(2), x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PID"
                            DataTableIteration(1,:) = {date,time,0, x(1), 0, x(2), x(3), x(4), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                    end
                case "PI"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0,x(3), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, 0, x(3), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, x(3), x(4), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), 0, x(3), x(4), x(5), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                    end
                case "PID"
                    switch UserInputs.TEF_Controller.Typ
                        case "P"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3),x(4), 0, 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "I"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), 0, x(4), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PI"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), x(4), x(5), 0, optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                        case "PID"
                            DataTableIteration(1,:) = {date,time,x(1), x(2), x(3), x(4), x(5), x(6), optimValues.iteration, optimValues.funccount, optimValues.fval, optimValues.procedure};
                    end
            end
            
           dlmwrite('optimization_log.csv', [DataTableIteration.IPC_KP, DataTableIteration.IPC_KI, DataTableIteration.IPC_KD,...
                DataTableIteration.TEF_KP, DataTableIteration.TEF_KI, DataTableIteration.TEF_KD,  optimValues.iteration],'-append'); %#ok<DLMWT>
 
            history = [history; DataTableIteration];
        end
        % Plots erstellen
        if isequal(state,'done')
            % Iteration = 0 : 1 : table2array(history(height(history), 9));
            for i = 1 : height(history)
                if i >= 2 && table2array(history(i, 10)) == table2array(history(i-1, 10))
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


            if length(Iteration) == length(IterationFunValue)
                OtimPlot1 = figure;
                plot(Iteration,IterationFunValue,'diamond','MarkerEdgeColor','k','MarkerFaceColor','m');
                title('Entwiklung der Kostenfunktiosergebnisse');
                xlabel('Iteration [-]');
                ylabel('Wert der Kostenfunktion');
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
                title('Entwicklung der Kostenfunktiosergebnisse');
                xlabel('Anzahl der Simulationen [-]');
                ylabel('Wert der Kostenfunktion');
                grid on
                saveas(OtimPlot2,fullfile(OptimizationResultsFolderPath,'SimCount_Plot.fig'));
            else
                fprintf('\nDie Vektoren FunCountAtInteration und IterationFunValue in der Funktion fminsearchStart haben nicht die selbe länge.\n');
            end
        end
    end

end

