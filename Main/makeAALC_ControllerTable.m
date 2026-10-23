function Tab = makeAALC_ControllerTable(set)
%MAKEAALC_CONTROLLERTABLE AALC gains and load changes over the wind speed
%   Tab = makeAALC_ControllerTable collects the AALC gains (IPC K_P, K_I and
%   TEF K_P, 8 deg/s, IPC/TEF fade-in) and their effect on the optimization
%   set (NTM class A, TurbKlasseA) from the saved results of
%   checkIPC_WindSpeeds, without new simulations:
%   - 4, 6, 8 m/s: fminsearch optimum of that wind speed (runAALC_BelowRated),
%     sweeps AALCbelow_<ws>mps_TurbKlasseA
%   - 10-25 m/s: gains of 18 m/s (fmincon, best.RL08_IPC_TEF_KP_fmincon),
%     sweep AALCfromIPC_RL08_TurbKlasseA
%   Tab = makeAALC_ControllerTable("test") uses the test set (NTM class A,
%   new seed, TurbKlasseAnewSeed) instead: 4, 6, 8 m/s from the cross check
%   of runAALC_BelowRated and 10, 12-25 m/s from the sweep
%   AALCfromIPC_RL08_TurbKlasseAnewSeed. The test set has no 11 and 13 m/s;
%   11 m/s is taken from the optimization set (marked in Source).
%
%   Columns: wind speed, gains, worst blade root DEL change (max. of the
%   three blades), tower base DEL change, mean power change, std power
%   change (all in %, negative = reduction; std from the saved time series,
%   t >= 66 s), and the pitch activity ADC (mean absolute pitch rate) as
%   absolute change in deg/s and in % (the baseline ADC is 0 below rated,
%   so the relative change is Inf there).
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/AALC_ControllerTable.csv/.mat
%   (optimization set) or AALC_ControllerTable_TestSet.csv/.mat (test set).
%   Start from the Main folder.

arguments
    set (1,1) string {mustBeMember(set, ["optimization", "test"])} = "optimization"
end
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
pp = fullfile(pwd, 'Post_processing');
if set == "test"
    windSet = 'TurbKlasseAnewSeed';
    ws = [4 6 8 10 11 12 14 16 18 20 22 24 25]';
    fOut = 'AALC_ControllerTable_TestSet';
else
    windSet = 'TurbKlasseA';
    ws = [4 6 8 10 11 12 13 14 16 18 20 22 24 25]';
    fOut = 'AALC_ControllerTable';
end

n = numel(ws);
v = nan(n, 1);
Tab = table(ws, v, v, v, v, v, v, v, v, v, strings(n, 1), 'VariableNames', {'WindSpeed_mps', ...
    'IPC_K_P', 'IPC_K_I', 'TEF_K_P', 'RelDEL_WorstBlade_pct', 'RelDEL_Tower_pct', ...
    'RelMeanPower_pct', 'RelStdPower_pct', 'DeltaADC_degps', 'RelADC_pct', 'Source'});
for k = 1:n
    if ws(k) < 10
        name = sprintf('AALCbelow_%02dmps_%s', ws(k), windSet);           % gains of the same wind speed
        Tab.Source(k) = sprintf("gains of %d m/s (fminsearch)", ws(k));
    elseif ws(k) == 11 && set == "test"
        name = 'AALCfromIPC_RL08_TurbKlasseA';                             % no 11 m/s in the test set
        Tab.Source(k) = "gains of 18 m/s (fmincon), simulated on the OPTIMIZATION set";
    else
        name = ['AALCfromIPC_RL08_' windSet];                              % gains of 18 m/s
        Tab.Source(k) = "gains of 18 m/s (fmincon)";
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
writetable(Tab, fullfile(fadeIn, [fOut '.csv']));
save(fullfile(fadeIn, [fOut '.mat']), 'Tab');
end

function s = stdPower(ts)
% Std of GenPwr (kW) in the evaluation window t >= 66 s
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
p = ts.OutData(:, OutList == "GenPwr");
s = std(p(t >= 66));
end
