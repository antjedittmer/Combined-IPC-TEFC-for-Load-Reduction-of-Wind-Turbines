function Tab = makeIPC_SummaryTable(tStart)
%MAKEIPC_SUMMARYTABLE IPC evaluation criteria averaged over the above rated wind speeds
%   Tab = makeIPC_SummaryTable averages the evaluation criteria of the PI-IPC
%   with the gains optimized for 8 deg/s at 18 m/s (fmincon, IPC/TEF
%   fade-in, K_P = 1.2219, K_I = 0.3702) for the optimization set (NTM
%   class A), the test set (NTM class A, new seed) and the verification set
%   with NTM class B over the wind speed ranges 12-25 m/s (above rated),
%   18-25 m/s and 18 m/s, from the saved results of checkIPC_WindSpeeds (as
%   makeAALC_SummaryTable, no new simulations). Wind speeds without a wind
%   field are left out (the test set has no 13 m/s).
%
%   Criteria (ratio to the baseline, < 1 = reduction), as
%   makeAALC_SummaryTable:
%   - C_DEL_b (sum of the three blade root DELs RootMyc1..3, Woehler
%     exponent 10), C_DEL_t (tower base DEL TwrBsMyt) and C_DEL_tt (tower
%     top fore-aft DEL YawBrMyp), both Woehler exponent 4, as in the thesis
%     and runParetoVerif2 of the qLMPC repository (the IPC optimization
%     uses 8 for the worst blade and 3 for the tower), DELs from the time
%     series, t >= tStart; C_P (mean power), C_dP (std power,
%     t >= tStart): mean of the ratios of the single wind speeds
%   - C_Act: actuator power as in the thesis (Eq. CAct_calc): mean over the
%     blades and time of |pitch rate * pitch moment RootMzb|, t >= tStart;
%     ratio of the means over the wind speeds
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/IPC_SummaryTable.csv/.mat
%   and the LaTeX table plotFunktionen/figIPCThesis/tab_IPC_summary.tex.
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
    'ws', {[12 13 14 16 18 20 22 24 25], [12 14 16 18 20 22 24 25], [12 13 14 16 18 20 22 24 25]});
ranges = struct('name', {'Above rated (12--25\,m/s)', '18--25\,m/s', '18\,m/s'}, ...
    'lim', {[12 25], [18 25], [18 18]});

rows = {};
for r = 1:numel(ranges)
    for s = 1:numel(sets)
        ws = sets(s).ws(sets(s).ws >= ranges(r).lim(1) & sets(s).ws <= ranges(r).lim(2));
        n = numel(ws);
        [blade, tower, towerTop, pMean, pStd, actO, actB] = deal(nan(n, 1));
        for k = 1:n
            folder = fullfile(pp, ['IPCcheck_fixedRL08_' sets(s).windSet sfx], sprintf('%02dmps', ws(k)));
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
        rows(end+1, :) = {string(ranges(r).name), string(sets(s).name), string(sets(s).turb), ...
            string(mat2str(ws)), mean(blade), mean(tower), mean(towerTop), mean(pMean), mean(pStd), sum(actO)/sum(actB)}; %#ok<AGROW>
    end
end
Tab = cell2table(rows, 'VariableNames', {'Range', 'Dataset', 'TurbClass', 'WindSpeeds_mps', ...
    'C_DEL_b', 'C_DEL_t', 'C_DEL_tt', 'C_P', 'C_dP', 'C_Act'});
disp(Tab);
writetable(Tab, fullfile(fadeIn, 'IPC_SummaryTable.csv'));
save(fullfile(fadeIn, 'IPC_SummaryTable.mat'), 'Tab');
writeTex(Tab, fullfile(pwd, 'plotFunktionen', 'figIPCThesis', 'tab_IPC_summary.tex'));
end

function writeTex(Tab, fTex)
fid = fopen(fTex, 'w');
closeF = onCleanup(@() fclose(fid));
p = @(varargin) fprintf(fid, varargin{:});
p('%% Created by makeIPC_SummaryTable on %s\n', datestr(now, 'yyyy-mm-dd')); %#ok<TNOW1,DATST>
p('\\begin{table}[h]\n    \\centering\n');
p(['    \\caption[Wind turbine evaluation criteria for IPC: Mean values of the optimization and verification datasets ' ...
    'over the above rated wind speeds]{\\label{tab:IPC_summary} Wind turbine evaluation criteria for IPC: Mean values ' ...
    'of the optimization and verification datasets over the above rated wind speed ranges, normalized by the baseline ' ...
    'without IPC. IPC gains optimized at 18\\,m/s with the pitch rate limit 8\\textdegree/s for all wind speeds: ' ...
    '$K_{P,\\text{IPC}} = 1.222$ and $K_{I,\\text{IPC}} = 0.370$. Criteria are blade (sum of the three blades, W\\"ohler exponent 10), tower base and tower top DELs (W\\"ohler exponent 4), power mean ' ...
    'and standard deviation (mean of the ratios of the single wind speeds), and actuator power (ratio of the mean ' ...
    'actuator powers). The first verification set has no wind field for 13\\,m/s.}\n']);
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
    p('        %s & %s & %s & %.2f & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', rng, Tab.Dataset(k), Tab.TurbClass(k), ...
        Tab.C_DEL_b(k), Tab.C_DEL_t(k), Tab.C_DEL_tt(k), Tab.C_P(k), Tab.C_dP(k), Tab.C_Act(k));
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
