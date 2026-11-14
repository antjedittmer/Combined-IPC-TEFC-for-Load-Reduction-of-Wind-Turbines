function [TabIPC, TabAALC] = makeSummaryFromWindSpeedTables(tabDir)
%MAKESUMMARYFROMWINDSPEEDTABLES Thesis summary tables from the wind speed tables
%   [TabIPC, TabAALC] = makeSummaryFromWindSpeedTables creates the IPC
%   (tab:IPC_summary) and AALC (tabone) summary tables of the thesis
%   directly from the wind speed tables IPCAALCtables/tab_IPC_windspeeds.tex
%   and tab_AALC_windspeeds.tex (makeIPCAALC_WindSpeedTables), without the
%   simulation results (MATLAB version of checkSummary.py):
%   - C_DEL_b, C_DEL_t, C_DEL_tt, C_P, C_dP: mean over the wind speeds of
%     the range
%   - C_Act: sum of P_Act / sum of P_Act,0 over the wind speeds of the
%     range; "--" for the below rated range
%   The wind speed tables contain rounded values, so single entries can
%   differ by one in the last digit from makeIPC_SummaryTable /
%   makeAALC_SummaryTable (e.g. IPC, Optim., 12-25 m/s: C_Act 5.36 instead
%   of 5.37).
%
%   Results: IPCAALCtables/tab_IPC_summary.tex and tab_AALC_summary.tex in
%   the layout of the thesis chapter.
%   makeSummaryFromWindSpeedTables(tabDir) reads and writes in tabDir
%   (default plotFunktionen/IPCAALCtables).

if nargin < 1, tabDir = fullfile(fileparts(mfilename('fullpath')), 'IPCAALCtables'); end
datasets = {'Optim.', 'Verif. 1', 'Verif. 2'};

ranges = struct('name', {'\begin{tabular}[c]{@{}l@{}}Above rated\\(12--25\,m/s)\end{tabular}', ...
    '18--25\,m/s', '18\,m/s'}, 'lim', {[12 25], [18 25], [18 18]});
W = readWindSpeedTable(fullfile(tabDir, 'tab_IPC_windspeeds.tex'), 2);
TabIPC = summarize(W, datasets, ranges);
writeTex(TabIPC, fullfile(tabDir, 'tab_IPC_summary.tex'), 'IPC');

ranges = struct('name', {'All (4--25\,m/s)', '\begin{tabular}[c]{@{}l@{}}Below rated\\(4--11\,m/s)\end{tabular}', ...
    '\begin{tabular}[c]{@{}l@{}}Above rated\\(12--25\,m/s)\end{tabular}', '18--25\,m/s', '18\,m/s'}, ...
    'lim', {[4 25], [4 11], [12 25], [18 25], [18 18]});
W = readWindSpeedTable(fullfile(tabDir, 'tab_AALC_windspeeds.tex'), 3);
TabAALC = summarize(W, datasets, ranges);
writeTex(TabAALC, fullfile(tabDir, 'tab_AALC_summary.tex'), 'AALC');
disp(TabIPC); disp(TabAALC);
end

function W = readWindSpeedTable(fTex, nGains)
% Rows of a wind speed table: dataset, turbulence class, wind speed, the five
% criteria C_DEL_b ... C_dP and the actuator powers P_Act,0 and P_Act
lines = splitlines(string(fileread(fTex)));
[ds, tc] = deal("");
rows = {};
for k = 1:numel(lines)
    c = strtrim(split(erase(strtrim(lines(k)), "\\"), "&"));
    if numel(c) < 10 || isempty(regexp(c(3), '^\d+$', 'once')), continue; end
    if c(1) ~= "", ds = c(1); tc = c(2); end
    v = str2double(c(4 + nGains:end));                       % after the gains; "--" -> NaN
    rows(end+1, :) = {ds, tc, str2double(c(3)), v(1:5)', v(6), v(7)}; %#ok<AGROW>
end
W = cell2table(rows, 'VariableNames', {'Dataset', 'TurbClass', 'WindSpeed_mps', 'C', 'P_Act_Baseline', 'P_Act'});
end

function Tab = summarize(W, datasets, ranges)
% Mean criteria of the wind speed ranges, C_Act as ratio of the summed actuator powers
rows = {};
for r = 1:numel(ranges)
    for s = 1:numel(datasets)
        m = W.Dataset == datasets{s} & W.WindSpeed_mps >= ranges(r).lim(1) & W.WindSpeed_mps <= ranges(r).lim(2);
        cAct = sum(W.P_Act(m))/sum(W.P_Act_Baseline(m));
        if ranges(r).lim(2) < 12, cAct = NaN; end                % baseline actuator power close to 0
        tc = W.TurbClass(find(W.Dataset == datasets{s}, 1));
        c = mean(W.C(m, :), 1);
        rows(end+1, :) = {string(ranges(r).name), string(datasets{s}), tc, ...
            mat2str(W.WindSpeed_mps(m)'), c(1), c(2), c(3), c(4), c(5), cAct}; %#ok<AGROW>
    end
end
Tab = cell2table(rows, 'VariableNames', {'Range', 'Dataset', 'TurbClass', 'WindSpeeds_mps', ...
    'C_DEL_b', 'C_DEL_t', 'C_DEL_tt', 'C_P', 'C_dP', 'C_Act'});
end

function writeTex(Tab, fTex, ctrl)
% Summary table in the layout of the thesis chapter
fid = fopen(fTex, 'w');
closeF = onCleanup(@() fclose(fid));
p = @(varargin) fprintf(fid, varargin{:});
p('%% Created by makeSummaryFromWindSpeedTables from tab_%s_windspeeds.tex on %s\n', ctrl, ...
    datestr(now, 'yyyy-mm-dd')); %#ok<TNOW1,DATST>
p('\\begin{table}[h]\n    \\centering\n');
if strcmp(ctrl, 'IPC')
    p(['    \\caption[Evaluation criteria for IPC: Mean values of the optimization and verification datasets over ' ...
        'above-rated wind speed ranges]{\\label{tab:IPC_summary} Evaluation criteria for IPC: Mean values of the ' ...
        'optimization and verification datasets over above-rated wind speed ranges, normalized by the baseline PI ' ...
        'without IPC; values below 1 indicate a reduction. IPC gains optimized at 18\\,m/s with the pitch rate ' ...
        'limit 8\\textdegree/s: $K_{\\text{P,IPC}} = 1.222$ and $K_{\\text{I,IPC}} = 0.370$. Criteria are blade, ' ...
        'tower base and tower top DELs, power mean and standard deviation, and pitch actuator power. The first ' ...
        'verification set has no wind field for 13\\,m/s.}\n']);
else
    p(['    \\caption[Evaluation criteria for AALC: Mean values of the optimization and verification datasets over ' ...
        'different wind speed ranges.]{Evaluation criteria for AALC: Mean values of the optimization and ' ...
        'verification datasets over different wind speed ranges, normalized by the baseline PI; values below 1 ' ...
        'indicate a reduction. From 10\\,m/s on, the AALC gains optimized at 18\\,m/s are used: ' ...
        '$K_{\\text{P,IPC}} = 0.082$, $K_{\\text{I,IPC}} = 0.669$ and $K_{\\text{P,TEFC}} = 0.641$; below, the ' ...
        'gains are scheduled with the gains optimized at 4, 6 and 8\\,m/s. Criteria are blade, tower base and ' ...
        'tower top DELs, power mean and standard deviation, and pitch actuator power (not given below rated, ' ...
        'where the baseline actuator power is close to zero). The first verification set has no wind fields ' ...
        'for 11 and 13\\,m/s.}\n']);
end
p('    \\begin{tabular}{@{}l*{8}{c}@{}}\n        \\toprule\n');
p(['        Wind speeds & Dataset & Turb. class & $C_{\\text{DEL},b}$ & $C_{\\text{DEL},t,\\text{Base}}$ & ' ...
    '$C_{\\text{DEL},t,\\text{Top}}$ & $C_{\\bar{P}}$ & $C_{\\delta P}$ & $C_{\\text{Act}}$ \\\\\n        \\midrule\n']);
for k = 1:height(Tab)
    newRange = k == 1 || Tab.Range(k) ~= Tab.Range(k-1);
    if k > 1 && newRange, p('        \\midrule\n'); end
    rng = '';
    if newRange, rng = sprintf('\\multirow{3}{*}{%s}', Tab.Range(k)); end
    if isnan(Tab.C_Act(k)), act = '--'; else, act = sprintf('%.2f', Tab.C_Act(k)); end
    p('        %s & %s & %s & %.2f & %.2f & %.2f & %.2f & %.2f & %s \\\\\n', rng, Tab.Dataset(k), Tab.TurbClass(k), ...
        Tab.C_DEL_b(k), Tab.C_DEL_t(k), Tab.C_DEL_tt(k), Tab.C_P(k), Tab.C_dP(k), act);
end
p('        \\bottomrule\n    \\end{tabular}\n');
if strcmp(ctrl, 'AALC'), p('    \\label{tabone}\n'); end
p('\\end{table}\n');
end
