function Tab = makeAALC_ControllerTable(set)
%MAKEAALC_CONTROLLERTABLE AALC gains and load changes over the wind speed
%   Tab = makeAALC_ControllerTable collects the AALC gains (IPC K_P, K_I and
%   TEF K_P, 8 deg/s, IPC/TEF fade-in) and their effect on the optimization
%   set (NTM class A, TurbKlasseA) from existing results, without new
%   simulations. Rows: 4, 6, 8 m/s (fminsearch optimum of that wind speed,
%   runAALC_BelowRated) and 12-25 m/s (gains of 18 m/s, fmincon,
%   best.RL08_IPC_TEF_KP_fmincon, repeated). The changes relative to the
%   baseline (IPC and TEF off) exist on the optimization set only for 4, 6,
%   8 and 18 m/s; the other rows are NaN. The std of the power needs a
%   time series, which exists only for 18 m/s.
%
%   Columns: wind speed, gains, worst blade root DEL change (max. of the
%   three blades), tower base DEL change, mean power change, std power
%   change (all in %, negative = reduction), and the pitch activity ADC
%   (mean absolute pitch rate) as absolute change in deg/s and in % (the
%   baseline ADC is 0 below rated, so the relative change is Inf there).
%
%   Tab = makeAALC_ControllerTable("test") uses the test set (NTM class A,
%   new seed, TurbKlasseAnewSeed) instead: 4, 6, 8 m/s from the cross check
%   of runAALC_BelowRated (gains of the same wind speed) and 10, 12-25 m/s
%   from the sweep AALCfromIPC_RL08_TurbKlasseAnewSeed (gains of 18 m/s), all
%   with saved time series, so that the std of the power exists for every
%   row. The test set has no 11 and 13 m/s; 11 m/s is taken from the
%   optimization set (AALCfromIPC_RL08_TurbKlasseA, gains of 18 m/s).
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/AALC_ControllerTable.csv/.mat
%   (optimization set) or AALC_ControllerTable_TestSet.csv/.mat (test set).
%   Start from the Main folder.

arguments
    set (1,1) string {mustBeMember(set, ["optimization", "test"])} = "optimization"
end
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
if set == "test"
    Tab = testSetTable(fadeIn);
    return
end
ws = [4 6 8 12 13 14 16 18 20 22 24 25]';
n = numel(ws);
v = nan(n, 1);
Tab = table(ws, v, v, v, v, v, v, v, v, v, strings(n, 1), 'VariableNames', {'WindSpeed_mps', ...
    'IPC_K_P', 'IPC_K_I', 'TEF_K_P', 'RelDEL_WorstBlade_pct', 'RelDEL_Tower_pct', ...
    'RelMeanPower_pct', 'RelStdPower_pct', 'DeltaADC_degps', 'RelADC_pct', 'Source'});

for k = 1:n
    if ws(k) < 12
        folder = fullfile(fadeIn, sprintf('RL08_IPC_TEF_KP_%02dmps_fminsearch', ws(k)));
    else
        folder = fullfile(fadeIn, 'RL08_IPC_TEF_KP_fmincon');            % tuned at 18 m/s
    end
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    r = R.Results;
    Tab{k, {'IPC_K_P', 'IPC_K_I', 'TEF_K_P'}} = [r.K_P, r.K_I, r.TEF_K_P];
    if ws(k) >= 12 && ws(k) ~= 18
        Tab.Source(k) = "gains of 18 m/s, no simulation at this wind speed";
        continue
    end
    Tab.RelDEL_WorstBlade_pct(k) = 100*max(r.RelChange.RootMyc);
    Tab.RelDEL_Tower_pct(k)      = 100*r.RelChange.TwrBsMyt;
    Tab.RelMeanPower_pct(k)      = 100*r.RelChange.Power;
    Tab.DeltaADC_degps(k)        = r.Optimum.ADC - r.Baseline.ADC;
    Tab.RelADC_pct(k)            = 100*r.RelChange.ADC;
    Tab.Source(k) = string(r.Optimizer) + " at this wind speed";
    if ws(k) == 18
        % Std of the power from the saved time series (evaluation window from 66 s)
        S = load(fullfile(fadeIn, 'TimeSeries', 'TimeSeries_RL08_IPCTEF.mat'), 'TimeSeries');
        sd = structfun(@(ts) stdPower(ts), S.TimeSeries);
        Tab.RelStdPower_pct(k) = 100*(sd(2)/sd(1) - 1);                    % Optimum / Baseline
    end
end
disp(Tab);
writetable(Tab, fullfile(fadeIn, 'AALC_ControllerTable.csv'));
save(fullfile(fadeIn, 'AALC_ControllerTable.mat'), 'Tab');
end

function Tab = testSetTable(fadeIn)
% Table on the test set from the saved sweep results and time series
pp = fullfile(pwd, 'Post_processing');
ws = [4 6 8 10 11 12 14 16 18 20 22 24 25]';
n = numel(ws);
v = nan(n, 1);
Tab = table(ws, v, v, v, v, v, v, v, v, v, strings(n, 1), 'VariableNames', {'WindSpeed_mps', ...
    'IPC_K_P', 'IPC_K_I', 'TEF_K_P', 'RelDEL_WorstBlade_pct', 'RelDEL_Tower_pct', ...
    'RelMeanPower_pct', 'RelStdPower_pct', 'DeltaADC_degps', 'RelADC_pct', 'Source'});
for k = 1:n
    if ws(k) < 10
        name = sprintf('AALCbelow_%02dmps_TurbKlasseAnewSeed', ws(k));    % gains of the same wind speed
        Tab.Source(k) = sprintf("gains of %d m/s (fminsearch, optimization set)", ws(k));
    elseif ws(k) == 11
        name = 'AALCfromIPC_RL08_TurbKlasseA';                             % no 11 m/s in the test set
        Tab.Source(k) = "gains of 18 m/s (fmincon), simulated on the OPTIMIZATION set";
    else
        name = 'AALCfromIPC_RL08_TurbKlasseAnewSeed';                      % gains of 18 m/s
        Tab.Source(k) = "gains of 18 m/s (fmincon, optimization set)";
    end
    folder = fullfile(pp, ['IPCcheck_' name], sprintf('%02dmps', ws(k)));
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    r = R.Results(1);
    Tab{k, {'IPC_K_P', 'IPC_K_I', 'TEF_K_P'}} = [r.K_P, r.K_I, r.TEF_K_P];
    Tab.RelDEL_WorstBlade_pct(k) = 100*max(r.RelChange.RootMyc);
    Tab.RelDEL_Tower_pct(k)      = 100*r.RelChange.TwrBsMyt;
    Tab.RelMeanPower_pct(k)      = 100*r.RelChange.Power;
    Tab.DeltaADC_degps(k)        = r.Optimum.ADC - r.Baseline.ADC;
    Tab.RelADC_pct(k)            = 100*r.RelChange.ADC;
    S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
    Tab.RelStdPower_pct(k) = 100*(stdPower(S.TimeSeries.Optimum)/stdPower(S.TimeSeries.Baseline) - 1);
end
disp(Tab);
writetable(Tab, fullfile(fadeIn, 'AALC_ControllerTable_TestSet.csv'));
save(fullfile(fadeIn, 'AALC_ControllerTable_TestSet.mat'), 'Tab');
end

function s = stdPower(ts)
% Std of GenPwr (kW) in the evaluation window t >= 66 s
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
p = ts.OutData(:, OutList == "GenPwr");
s = std(p(t >= 66));
end
