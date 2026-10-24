function Tab = makeAALC_SummaryTable()
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
%   - C_DEL_b (worst of the three blade root DELs), C_DEL_t (tower base
%     DEL), C_P (mean power), C_dP (std power, t >= 66 s): mean of the
%     ratios of the single wind speeds
%   - C_Act: ratio of the means of the mean absolute pitch rate (ADC), since
%     the baseline pitch rate is 0 below rated; NaN ("--" in LaTeX) for
%     4-11 m/s, where the baseline pitch rate is close to 0
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/AALC_SummaryTable.csv/.mat
%   and the LaTeX table plotFunktionen/figIPCThesis/tab_AALC_summary.tex.
%   Start from the Main folder.

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
        [blade, tower, pMean, pStd, adcO, adcB] = deal(nan(n, 1));
        for k = 1:n
            if ws(k) < 10
                name = sprintf('AALCbelow_%02dmps_%s', ws(k), sets(s).windSet);
            else
                name = ['AALCfromIPC_RL08_' sets(s).windSet];
            end
            folder = fullfile(pp, ['IPCcheck_' name], sprintf('%02dmps', ws(k)));
            R = load(fullfile(folder, 'Results.mat'), 'Results');
            x = R.Results(1);
            blade(k) = 1 + max(x.RelChange.RootMyc);
            tower(k) = 1 + x.RelChange.TwrBsMyt;
            pMean(k) = 1 + x.RelChange.Power;
            adcO(k) = x.Optimum.ADC;
            adcB(k) = x.Baseline.ADC;
            S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
            pStd(k) = stdPower(S.TimeSeries.Optimum)/stdPower(S.TimeSeries.Baseline);
        end
        cAct = sum(adcO)/sum(adcB);
        if ranges(r).lim(2) < 12, cAct = NaN; end                         % baseline pitch rate close to 0
        rows(end+1, :) = {string(ranges(r).name), string(sets(s).name), string(sets(s).turb), ...
            string(mat2str(ws)), mean(blade), mean(tower), mean(pMean), mean(pStd), cAct}; %#ok<AGROW>
    end
end
Tab = cell2table(rows, 'VariableNames', {'Range', 'Dataset', 'TurbClass', 'WindSpeeds_mps', ...
    'C_DEL_b', 'C_DEL_t', 'C_P', 'C_dP', 'C_Act'});
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
    'optimized at 4, 6 and 8\\,m/s. Criteria are tower base and blade DELs, power mean and standard deviation ' ...
    '(mean of the ratios of the single wind speeds), and the pitch activity (ratio of the mean pitch rates, ' ...
    'since the baseline pitch is constant at low wind speeds; not given below rated, where the baseline ' ...
    'pitch rate is close to zero). The first verification set has no wind ' ...
    'fields for 11 and 13\\,m/s.}\n']);
p('    \\begin{tabular}{@{}l*{7}{c}@{}}\n        \\toprule\n');
p(['        Wind speeds & Dataset & Turb. class & $C_{\\text{DEL},b}$ & $C_{\\text{DEL},t,\\text{Base}}$ & ' ...
    '$C_{\\bar{P}}$ & $C_{\\delta P}$ & $C_{\\text{Act}}$ \\\\\n        \\midrule\n']);
for k = 1:height(Tab)
    if k > 1 && Tab.Range(k) ~= Tab.Range(k-1), p('        \\midrule\n'); end
    if k == 1 || Tab.Range(k) ~= Tab.Range(k-1)
        rng = sprintf('\\multirow{3}{*}{%s}', Tab.Range(k));
    else
        rng = '';
    end
    if isnan(Tab.C_Act(k)), act = '--'; else, act = sprintf('%.2f', Tab.C_Act(k)); end
    p('        %s & %s & %s & %.2f & %.2f & %.2f & %.2f & %s \\\\\n', rng, Tab.Dataset(k), Tab.TurbClass(k), ...
        Tab.C_DEL_b(k), Tab.C_DEL_t(k), Tab.C_P(k), Tab.C_dP(k), act);
end
p('        \\bottomrule\n    \\end{tabular}\n\\end{table}\n');
end

function s = stdPower(ts)
% Std of GenPwr (kW) in the evaluation window t >= 66 s
OutList = strtrim(string(ts.OutList));
t = ts.OutData(:, OutList == "Time");
p = ts.OutData(:, OutList == "GenPwr");
s = std(p(t >= 66));
end
