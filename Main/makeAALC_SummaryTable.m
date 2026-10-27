function Tab = makeAALC_SummaryTable(tStart)
%MAKEAALC_SUMMARYTABLE AALC evaluation criteria averaged over wind speed ranges
%   Tab = makeAALC_SummaryTable averages the AALC evaluation criteria of the
%   optimization set (NTM class A), the test set (NTM class A, new seed) and
%   the verification set with NTM class B over the wind speed ranges
%   4-25 m/s (all), 4-11 m/s (below rated), 12-25 m/s (above rated),
%   18-25 m/s and 18 m/s, from the
%   saved results of checkIPC_WindSpeeds (as makeAALC_ControllerTable, no
%   new simulations). Gains: tuned at each wind speed below rated, the gains
%   of 18 m/s from 10 m/s on. Wind speeds without a wind field are left out
%   (the test set has no 11 and 13 m/s).
%
%   Criteria (ratio to the baseline, < 1 = reduction):
%   - C_DEL_b (sum of the three blade root DELs RootMyc1..3, Woehler
%     exponent 10), C_DEL_t (tower base DEL TwrBsMyt) and C_DEL_tt (tower
%     top fore-aft DEL YawBrMyp), both Woehler exponent 4, as in the thesis
%     and runParetoVerif2 of the qLMPC repository (the IPC optimization
%     uses 8 for the worst blade and 3 for the tower), DELs from the time
%     series, t >= tStart; C_P (mean power), C_dP (std power,
%     t >= tStart): mean of the ratios of the single wind speeds
%   - C_Act: actuator power as in the thesis (Eq. CAct_calc, as
%     calculateEvalCriteria of the qLMPC repository): mean over the blades
%     and time of |pitch rate * pitch moment RootMzb|, t >= tStart; ratio of
%     the means over the wind speeds, since the baseline actuator power is
%     close to 0 below rated; NaN ("--" in LaTeX) for 4-11 m/s
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/AALC_SummaryTable.csv/.mat
%   and the LaTeX table plotFunktionen/figIPCThesis/tab_AALC_summary.tex.
%   Start from the Main folder.
%   tStart: start of the evaluation window in s (default 60). The runs with
%   the FAST output from tStart (checkIPC_WindSpeeds, TStartLog) are in the
%   folders with the suffix _T<tStart>; tStart = 66: the original runs.

if nargin < 1 || isempty(tStart), tStart = 60; end
sfx = ''; % folder suffix of the runs with the output from tStart
if tStart ~= 66, sfx = sprintf('_T%02d', tStart); end
mBlade = 10; % Woehler exponents: blades (GFRP) and tower (steel)
mTower = 4;
pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
sets = struct('name', {'Optim.', 'Verif. 1', 'Verif. 2'}, 'turb', {'A', 'A', 'B'}, ...
    'windSet', {'TurbKlasseA', 'TurbKlasseAnewSeed', 'KlasseB'}, ...
    'ws', {[4 6 8 10 11 12 13 14 16 18 20 22 24 25], [4 6 8 10 12 14 16 18 20 22 24 25], ...
           [4 6 8 10 11 12 13 14 16 18 20 22 24 25]});
ranges = struct('name', {'All (4--25\,m/s)', 'Below rated (4--11\,m/s)', 'Above rated (12--25\,m/s)', ...
    '18--25\,m/s', '18\,m/s'}, 'lim', {[4 25], [4 11], [12 25], [18 25], [18 18]});

rows = {};
for r = 1:numel(ranges)
    for s = 1:numel(sets)
        ws = sets(s).ws(sets(s).ws >= ranges(r).lim(1) & sets(s).ws <= ranges(r).lim(2));
        n = numel(ws);
        [blade, tower, towerTop, pMean, pStd, actO, actB] = deal(nan(n, 1));
        for k = 1:n
            if ws(k) < 10
                name = sprintf('AALCbelow_%02dmps_%s', ws(k), sets(s).windSet);
            else
                name = ['AALCfromIPC_RL08_' sets(s).windSet];
            end
            folder = fullfile(pp, ['IPCcheck_' name sfx], sprintf('%02dmps', ws(k)));
            R = load(fullfile(folder, 'Results.mat'), 'Results');
            x = R.Results(1);
            pMean(k) = 1 + x.RelChange.Power;
            S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
            blade(k) = delBlades(S.TimeSeries.Optimum, mBlade, tStart)/delBlades(S.TimeSeries.Baseline, mBlade, tStart);
            tower(k) = delChannel(S.TimeSeries.Optimum, "TwrBsMyt", mTower, tStart)/delChannel(S.TimeSeries.Baseline, "TwrBsMyt", mTower, tStart);
            towerTop(k) = delChannel(S.TimeSeries.Optimum, "YawBrMyp", mTower, tStart)/delChannel(S.TimeSeries.Baseline, "YawBrMyp", mTower, tStart);
            pStd(k) = stdPower(S.TimeSeries.Optimum, tStart)/stdPower(S.TimeSeries.Baseline, tStart);
            actO(k) = actuatorPower(S.TimeSeries.Optimum, tStart);
            actB(k) = actuatorPower(S.TimeSeries.Baseline, tStart);
        end
        cAct = sum(actO)/sum(actB);
        if ranges(r).lim(2) < 12, cAct = NaN; end                         % baseline actuator power close to 0
        rows(end+1, :) = {string(ranges(r).name), string(sets(s).name), string(sets(s).turb), ...
            string(mat2str(ws)), mean(blade), mean(tower), mean(towerTop), mean(pMean), mean(pStd), cAct}; %#ok<AGROW>
    end
end
Tab = cell2table(rows, 'VariableNames', {'Range', 'Dataset', 'TurbClass', 'WindSpeeds_mps', ...
    'C_DEL_b', 'C_DEL_t', 'C_DEL_tt', 'C_P', 'C_dP', 'C_Act'});
disp(Tab);
writetable(Tab, fullfile(fadeIn, 'AALC_SummaryTable.csv'));
save(fullfile(fadeIn, 'AALC_SummaryTable.mat'), 'Tab');
writeTex(Tab, fullfile(pwd, 'plotFunktionen', 'figIPCThesis', 'tab_AALC_summary.tex'));
end

function writeTex(Tab, fTex)
fid = fopen(fTex, 'w');
closeF = onCleanup(@() fclose(fid));
p = @(varargin) fprintf(fid, varargin{:});
p('%% Created by makeAALC_SummaryTable on %s\n', datestr(now, 'yyyy-mm-dd')); %#ok<TNOW1,DATST>
p('\\begin{table}[h]\n    \\centering\n');
p(['    \\caption[Wind turbine evaluation criteria for AALC: Mean values of the optimization and verification datasets ' ...
    'over wind speed ranges]{\\label{tabone} Wind turbine evaluation criteria for AALC: Mean values of the ' ...
    'optimization and verification datasets over different wind speed ranges, normalized by the baseline without AALC. ' ...
    'From 10\\,m/s on, the AALC gains optimized at 18\\,m/s are used: $K_{P,\\text{IPC}} = 0.082$, ' ...
    '$K_{I,\\text{IPC}} = 0.669$ and $K_{P,\\text{TEFC}} = 0.641$; below, the gains are scheduled with the gains ' ...
    'optimized at 4, 6 and 8\\,m/s. Criteria are blade (sum of the three blades, W\\"ohler exponent 10), tower base and tower top DELs (W\\"ohler exponent 4), power mean and standard deviation ' ...
    '(mean of the ratios of the single wind speeds), and actuator power (ratio of the mean actuator powers, ' ...
    'since the baseline pitch is constant at low wind speeds; not given below rated, where the baseline ' ...
    'actuator power is close to zero). The first verification set has no wind ' ...
    'fields for 11 and 13\\,m/s.}\n']);
p('    \\begin{tabular}{@{}l*{8}{c}@{}}\n        \\toprule\n');
p(['        Wind speeds & Dataset & Turb. class & $C_{\\text{DEL},b}$ & $C_{\\text{DEL},t,\\text{Base}}$ & ' ...
    '$C_{\\text{DEL},t,\\text{Top}}$ & $C_{\\bar{P}}$ & $C_{\\delta P}$ & $C_{\\text{Act}}$ \\\\\n        \\midrule\n']);
for k = 1:height(Tab)
    if k > 1 && Tab.Range(k) ~= Tab.Range(k-1), p('        \\midrule\n'); end
    if k == 1 || Tab.Range(k) ~= Tab.Range(k-1)
        rng = sprintf('\\multirow{3}{*}{%s}', Tab.Range(k));
    else
        rng = '';
    end
    if isnan(Tab.C_Act(k)), act = '--'; else, act = sprintf('%.2f', Tab.C_Act(k)); end
    p('        %s & %s & %s & %.2f & %.2f & %.2f & %.2f & %.2f & %s \\\\\n', rng, Tab.Dataset(k), Tab.TurbClass(k), ...
        Tab.C_DEL_b(k), Tab.C_DEL_t(k), Tab.C_DEL_tt(k), Tab.C_P(k), Tab.C_dP(k), act);
end
p('        \\bottomrule\n    \\end{tabular}\n\\end{table}\n');
end

function D = delChannel(ts, name, m, tStart)
% DEL of the channel name in the evaluation window t >= tStart, Woehler exponent m
% (as optimizeIPC_PI_RateLimits: 1 Hz equivalent frequency, half cycles count 0.5)
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
idx = t >= tStart;
c = rainflow(ts.OutData(idx, OutList == name));
D = (sum(c(:, 1) .* c(:, 2).^m) / (t(find(idx, 1, 'last')) - t(find(idx, 1))))^(1/m);
end

function D = delBlades(ts, m, tStart)
% Sum of the DELs of the three blade root out-of-plane moments RootMyc1..3
D = 0;
for b = 1:3
    D = D + delChannel(ts, "RootMyc" + b, m, tStart);
end
end

function s = stdPower(ts, tStart)
% Std of GenPwr (kW) in the evaluation window t >= tStart
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
p = ts.OutData(:, OutList == "GenPwr");
s = std(p(t >= tStart));
end

function a = actuatorPower(ts, tStart)
% Actuator power (Eq. CAct_calc of the thesis): mean over the blades and time of
% |pitch rate (deg/s) * pitch moment RootMzb (kNm)| in the evaluation window t >= tStart
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
idx = t >= tStart;
a = 0;
for b = 1:3
    beta = ts.OutData(idx, OutList == "BldPitch" + b);
    mz = ts.OutData(idx, OutList == "RootMzb" + b);
    a = a + mean(abs(diff(beta) ./ diff(t(idx)) .* mz(1:end-1)))/3;
end
end
