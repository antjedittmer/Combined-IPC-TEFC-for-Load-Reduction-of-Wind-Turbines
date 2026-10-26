function Tab = makeIPC_SummaryTable()
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
%   - C_DEL_b (worst of the three blade root DELs), C_DEL_t (tower base
%     DEL), C_DEL_tt (tower top fore-aft DEL, YawBrMyp, Woehler exponent 3
%     as the tower base, t >= 66 s), C_P (mean power), C_dP (std power,
%     t >= 66 s): mean of the ratios of the single wind speeds
%   - C_Act: actuator power as in the thesis (Eq. CAct_calc): mean over the
%     blades and time of |pitch rate * pitch moment RootMzb|, t >= 66 s;
%     ratio of the means over the wind speeds
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/IPC_SummaryTable.csv/.mat
%   and the LaTeX table plotFunktionen/figIPCThesis/tab_IPC_summary.tex.
%   Start from the Main folder.

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
            folder = fullfile(pp, ['IPCcheck_fixedRL08_' sets(s).windSet], sprintf('%02dmps', ws(k)));
            R = load(fullfile(folder, 'Results.mat'), 'Results');
            x = R.Results(1);
            blade(k) = 1 + max(x.RelChange.RootMyc);
            tower(k) = 1 + x.RelChange.TwrBsMyt;
            pMean(k) = 1 + x.RelChange.Power;
            S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
            towerTop(k) = delChannel(S.TimeSeries.Optimum, "YawBrMyp", 3)/delChannel(S.TimeSeries.Baseline, "YawBrMyp", 3);
            pStd(k) = stdPower(S.TimeSeries.Optimum)/stdPower(S.TimeSeries.Baseline);
            actO(k) = actuatorPower(S.TimeSeries.Optimum);
            actB(k) = actuatorPower(S.TimeSeries.Baseline);
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
    '$K_{P,\\text{IPC}} = 1.222$ and $K_{I,\\text{IPC}} = 0.370$. Criteria are blade, tower base and tower top DELs, power mean ' ...
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

function D = delChannel(ts, name, m)
% DEL of the channel name in the evaluation window t >= 66 s, Woehler exponent m
% (as optimizeIPC_PI_RateLimits: 1 Hz equivalent frequency, half cycles count 0.5)
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
idx = t >= 66;
c = rainflow(ts.OutData(idx, OutList == name));
D = (sum(c(:, 1) .* c(:, 2).^m) / (t(find(idx, 1, 'last')) - t(find(idx, 1))))^(1/m);
end

function s = stdPower(ts)
% Std of GenPwr (kW) in the evaluation window t >= 66 s
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
p = ts.OutData(:, OutList == "GenPwr");
s = std(p(t >= 66));
end

function a = actuatorPower(ts)
% Actuator power (Eq. CAct_calc of the thesis): mean over the blades and time of
% |pitch rate (deg/s) * pitch moment RootMzb (kNm)| in the evaluation window t >= 66 s
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
idx = t >= 66;
a = 0;
for b = 1:3
    beta = ts.OutData(idx, OutList == "BldPitch" + b);
    mz = ts.OutData(idx, OutList == "RootMzb" + b);
    a = a + mean(abs(diff(beta) ./ diff(t(idx)) .* mz(1:end-1)))/3;
end
end
