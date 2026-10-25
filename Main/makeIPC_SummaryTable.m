function Tab = makeIPC_SummaryTable()
%MAKEIPC_SUMMARYTABLE IPC evaluation criteria at 18 m/s
%   Tab = makeIPC_SummaryTable gives the evaluation criteria of the PI-IPC
%   with the gains optimized for 8 deg/s at 18 m/s (fmincon, IPC/TEF
%   fade-in, K_P = 1.2219, K_I = 0.3702) at 18 m/s for the optimization set
%   (NTM class A), the test set (NTM class A, new seed) and the
%   verification set with NTM class B, from the saved results of
%   checkIPC_WindSpeeds (no new simulations). Same criteria as
%   makeAALC_SummaryTable (ratio to the baseline, < 1 = reduction):
%   C_DEL_b (worst of the three blade root DELs), C_DEL_t (tower base DEL),
%   C_P (mean power), C_dP (std power, t >= 66 s) and C_Act (actuator
%   power, t >= 66 s).
%
%   Results: Results_IPC_PI_RateLimitOpt/FadeIn/IPC_SummaryTable.csv/.mat
%   and the LaTeX table plotFunktionen/figIPCThesis/tab_IPC_summary.tex.
%   Start from the Main folder.

pp = fullfile(pwd, 'Post_processing');
fadeIn = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn');
sets = struct('name', {'Optim.', 'Verif. 1', 'Verif. 2'}, 'turb', {'A', 'A', 'B'}, ...
    'folder', {'IPCcheck_repro_RL08_18mpsA', fullfile('IPCcheck_fixedRL08_TurbKlasseAnewSeed', '18mps'), ...
               fullfile('IPCcheck_fixedRL08_KlasseB', '18mps')});

rows = {};
for s = 1:numel(sets)
    folder = fullfile(pp, sets(s).folder);
    R = load(fullfile(folder, 'Results.mat'), 'Results');
    x = R.Results(1);
    S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
    rows(end+1, :) = {string(sets(s).name), string(sets(s).turb), string(x.WindFile), ...
        1 + max(x.RelChange.RootMyc), 1 + x.RelChange.TwrBsMyt, 1 + x.RelChange.Power, ...
        stdPower(S.TimeSeries.Optimum)/stdPower(S.TimeSeries.Baseline), ...
        actuatorPower(S.TimeSeries.Optimum)/actuatorPower(S.TimeSeries.Baseline)}; %#ok<AGROW>
end
Tab = cell2table(rows, 'VariableNames', {'Dataset', 'TurbClass', 'WindFile', ...
    'C_DEL_b', 'C_DEL_t', 'C_P', 'C_dP', 'C_Act'});
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
p(['    \\caption[Wind turbine evaluation criteria for IPC at 18\\,m/s: optimization and verification datasets]' ...
    '{\\label{tab:IPC_summary} Wind turbine evaluation criteria for IPC at 18\\,m/s for the optimization and ' ...
    'verification datasets, normalized by the baseline without IPC. IPC gains optimized at 18\\,m/s with the ' ...
    'pitch rate limit 8\\textdegree/s: $K_{P,\\text{IPC}} = 1.222$ and $K_{I,\\text{IPC}} = 0.370$. Criteria are ' ...
    'tower base and blade DELs, power mean and standard deviation, and actuator power.}\n']);
p('    \\begin{tabular}{@{}ll*{5}{c}@{}}\n        \\toprule\n');
p(['        Dataset & Turb. class & $C_{\\text{DEL},b}$ & $C_{\\text{DEL},t,\\text{Base}}$ & ' ...
    '$C_{\\bar{P}}$ & $C_{\\delta P}$ & $C_{\\text{Act}}$ \\\\\n        \\midrule\n']);
for k = 1:height(Tab)
    p('        %s & %s & %.2f & %.2f & %.2f & %.2f & %.2f \\\\\n', Tab.Dataset(k), Tab.TurbClass(k), ...
        Tab.C_DEL_b(k), Tab.C_DEL_t(k), Tab.C_P(k), Tab.C_dP(k), Tab.C_Act(k));
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
