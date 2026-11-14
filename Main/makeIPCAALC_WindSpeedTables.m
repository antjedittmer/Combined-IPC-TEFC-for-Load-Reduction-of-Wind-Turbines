function [TabIPC, TabAALC] = makeIPCAALC_WindSpeedTables(tStart)
%MAKEIPCAALC_WINDSPEEDTABLES Evaluation criteria of IPC and AALC per wind speed
%   [TabIPC, TabAALC] = makeIPCAALC_WindSpeedTables writes the values per
%   wind speed behind the summary tables of makeIPC_SummaryTable and
%   makeAALC_SummaryTable: the controller gains and the evaluation criteria
%   of every run of the optimization set (NTM class A), the test set (NTM
%   class A, new seed) and the verification set with NTM class B, from the
%   saved results of checkIPC_WindSpeeds (no new simulations):
%   - IPC: PI-IPC with the gains optimized for 8 deg/s at 18 m/s (fmincon,
%     IPC/TEF fade-in), 12-25 m/s, runs IPCcheck_fixedRL08_<set>
%   - AALC: below 10 m/s the gains tuned at that wind speed (runs
%     IPCcheck_AALCbelow_<ws>mps_<set>), from 10 m/s on the gains of 18 m/s
%     (runs IPCcheck_AALCfromIPC_RL08_<set>), 4-25 m/s
%
%   Criteria (ratio to the baseline, < 1 = reduction), computed as in the
%   summary tables: C_DEL_b (sum of the three blade root DELs RootMyc1..3,
%   Woehler exponent 10), C_DEL_t (tower base TwrBsMyt) and C_DEL_tt (tower
%   top YawBrMyp), both Woehler exponent 4, C_P (mean power), C_dP (std
%   power), and the actuator powers of the baseline and the controller
%   (mean over the blades and time of |pitch rate * RootMzb|, deg/s kNm)
%   with their ratio C_Act. The summary tables average C_DEL_b ... C_dP
%   over the wind speeds of a range and give C_Act as the ratio of the
%   summed actuator powers.
%
%   Results: plotFunktionen/IPCAALCtables/tab_IPC_windspeeds.tex and
%   tab_AALC_windspeeds.tex. Start from the Main folder.
%   tStart: start of the evaluation window in s (default 60, as the
%   summary tables); runs from the folders with the suffix _T<tStart>,
%   tStart = 66: the original runs.

if nargin < 1 || isempty(tStart), tStart = 60; end
sfx = '';
if tStart ~= 66, sfx = sprintf('_T%02d', tStart); end
pp = fullfile(pwd, 'Post_processing');
outDir = fullfile(pwd, 'plotFunktionen', 'IPCAALCtables');
if ~isfolder(outDir), mkdir(outDir); end

sets = struct('name', {'Optim.', 'Verif. 1', 'Verif. 2'}, 'turb', {'A', 'A', 'B'}, ...
    'windSet', {'TurbKlasseA', 'TurbKlasseAnewSeed', 'KlasseB'}, ...
    'ws', {[4 6 8 10 11 12 13 14 16 18 20 22 24 25], [4 6 8 10 12 14 16 18 20 22 24 25], ...
           [4 6 8 10 11 12 13 14 16 18 20 22 24 25]});

TabIPC = collect(sets, pp, sfx, tStart, 'IPC');
TabAALC = collect(sets, pp, sfx, tStart, 'AALC');
disp(TabIPC); disp(TabAALC);
writeTex(TabIPC, fullfile(outDir, 'tab_IPC_windspeeds.tex'), 'IPC', tStart);
writeTex(TabAALC, fullfile(outDir, 'tab_AALC_windspeeds.tex'), 'AALC', tStart);
end

function Tab = collect(sets, pp, sfx, tStart, ctrl)
% Gains and criteria of all runs of the controller ctrl ('IPC' or 'AALC')
mBlade = 10; % Woehler exponents: blades (GFRP) and tower (steel)
mTower = 4;
rows = {};
for s = 1:numel(sets)
    ws = sets(s).ws;
    if strcmp(ctrl, 'IPC'), ws = ws(ws >= 12); end
    for k = 1:numel(ws)
        if strcmp(ctrl, 'IPC')
            name = ['fixedRL08_' sets(s).windSet];
        elseif ws(k) < 10
            name = sprintf('AALCbelow_%02dmps_%s', ws(k), sets(s).windSet);
        else
            name = ['AALCfromIPC_RL08_' sets(s).windSet];
        end
        folder = fullfile(pp, ['IPCcheck_' name sfx], sprintf('%02dmps', ws(k)));
        R = load(fullfile(folder, 'Results.mat'), 'Results');
        x = R.Results(1);
        tefKP = NaN;
        if isfield(x, 'TEF_K_P'), tefKP = x.TEF_K_P; end
        S = load(fullfile(folder, 'TimeSeries_RL08.mat'), 'TimeSeries');
        O = S.TimeSeries.Optimum;
        B = S.TimeSeries.Baseline;
        actO = actuatorPower(O, tStart);
        actB = actuatorPower(B, tStart);
        row = {string(sets(s).name), string(sets(s).turb), ws(k), x.K_P, x.K_I, tefKP, ...
            delBlades(O, mBlade, tStart)/delBlades(B, mBlade, tStart), ...
            delChannel(O, "TwrBsMyt", mTower, tStart)/delChannel(B, "TwrBsMyt", mTower, tStart), ...
            delChannel(O, "YawBrMyp", mTower, tStart)/delChannel(B, "YawBrMyp", mTower, tStart), ...
            1 + x.RelChange.Power, stdPower(O, tStart)/stdPower(B, tStart), actB, actO, actO/actB};
        rows(end+1, :) = row; %#ok<AGROW>
    end
end
Tab = cell2table(rows, 'VariableNames', {'Dataset', 'TurbClass', 'WindSpeed_mps', 'IPC_K_P', 'IPC_K_I', ...
    'TEF_K_P', 'C_DEL_b', 'C_DEL_t', 'C_DEL_tt', 'C_P', 'C_dP', 'P_Act_Baseline', 'P_Act', 'C_Act'});
end

function writeTex(Tab, fTex, ctrl, tStart)
isAALC = strcmp(ctrl, 'AALC');
fid = fopen(fTex, 'w');
closeF = onCleanup(@() fclose(fid));
p = @(varargin) fprintf(fid, varargin{:});
p('%% Created by makeIPCAALC_WindSpeedTables on %s\n', datestr(now, 'yyyy-mm-dd')); %#ok<TNOW1,DATST>
p('%% Values per wind speed behind tab_%s_summary.tex (make%s_SummaryTable), evaluation from %d s\n', ctrl, ctrl, tStart);
p('\\begin{table}[htbp]\n    \\centering\n    \\footnotesize\n');
if isAALC
    p(['    \\caption[Wind turbine evaluation criteria for AALC per wind speed]{\\label{tab:AALC_windspeeds} ' ...
        'Wind turbine evaluation criteria for AALC per mean wind speed for the optimization and verification ' ...
        'datasets, normalized by the baseline without AALC (values behind Table~\\ref{tabone}). Below 10\\,m/s, ' ...
        'the gains optimized at that wind speed are used, from 10\\,m/s on the gains optimized at 18\\,m/s. ']);
else
    p(['    \\caption[Wind turbine evaluation criteria for IPC per wind speed]{\\label{tab:IPC_windspeeds} ' ...
        'Wind turbine evaluation criteria for IPC per mean wind speed for the optimization and verification ' ...
        'datasets, normalized by the baseline without IPC (values behind Table~\\ref{tab:IPC_summary}). ' ...
        'IPC gains optimized at 18\\,m/s with the pitch rate limit 8\\textdegree/s for all wind speeds. ']);
end
p(['Criteria are blade (sum of the three blades, W\\"ohler exponent 10), tower base and tower top DELs ' ...
    '(W\\"ohler exponent 4), power mean and standard deviation. $P_{\\text{Act},0}$ and $P_{\\text{Act}}$ are ' ...
    'the actuator powers (mean over the blades and time of $|\\dot\\beta\\, M_z|$ in \\textdegree/s\\,kNm) of the ' ...
    'baseline and the controller, $C_{\\text{Act}}$ their ratio']);
if isAALC
    p(' (not given below rated, where the baseline actuator power is close to zero)');
end
p('.}\n');
nG = 2 + isAALC;
p('    \\begin{adjustbox}{max width=\\textwidth}\n');
p('    \\begin{tabular}{@{}llr*{%d}{r}*{5}{c}rrc@{}}\n        \\toprule\n', nG);
p('        & & & \\multicolumn{%d}{c}{Gains} & & & & & & & & \\\\\n', nG);
p('        \\cmidrule(lr){4-%d}\n', 3 + nG);
p('        Dataset & Turb. class & $v$ (m/s) & IPC $K_P$ & IPC $K_I$');
if isAALC, p(' & TEF $K_P$'); end
p([' & $C_{\\text{DEL},b}$ & $C_{\\text{DEL},t,\\text{Base}}$ & $C_{\\text{DEL},t,\\text{Top}}$ & $C_{\\bar{P}}$ & ' ...
    '$C_{\\delta P}$ & $P_{\\text{Act},0}$ & $P_{\\text{Act}}$ & $C_{\\text{Act}}$ \\\\\n        \\midrule\n']);
for k = 1:height(Tab)
    r = Tab(k, :);
    if k > 1 && r.Dataset ~= Tab.Dataset(k-1), p('        \\midrule\n'); end
    if k == 1 || r.Dataset ~= Tab.Dataset(k-1)
        ds = r.Dataset; tc = r.TurbClass;
    else
        ds = ""; tc = "";
    end
    gains = sprintf('%.3f & %.3f', r.IPC_K_P, r.IPC_K_I);
    if isAALC, gains = sprintf('%s & %.3f', gains, r.TEF_K_P); end
    if isAALC && r.WindSpeed_mps < 12, act = '--'; else, act = sprintf('%.2f', r.C_Act); end
    p('        %s & %s & %d & %s & %.3f & %.3f & %.3f & %.3f & %.3f & %.1f & %.1f & %s \\\\\n', ds, tc, ...
        r.WindSpeed_mps, gains, r.C_DEL_b, r.C_DEL_t, r.C_DEL_tt, r.C_P, r.C_dP, r.P_Act_Baseline, r.P_Act, act);
end
p('        \\bottomrule\n    \\end{tabular}\n    \\end{adjustbox}\n\\end{table}\n');
end

function D = delChannel(ts, name, m, tStart)
% DEL of the channel name in the evaluation window t >= tStart, Woehler exponent m
% (as makeIPC_SummaryTable: 1 Hz equivalent frequency, half cycles count 0.5)
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
