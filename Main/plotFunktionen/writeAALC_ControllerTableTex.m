function writeAALC_ControllerTableTex(figDir)
%WRITEAALC_CONTROLLERTABLETEX LaTeX tables of the AALC gains and load changes
%   writeAALC_ControllerTableTex writes the AALC controller tables of
%   makeAALC_ControllerTable (FadeIn/AALC_ControllerTable.mat and
%   AALC_ControllerTable_TestSet.mat) as booktabs tables:
%   - tab_AALC_controller_optset.tex: optimization set (NTM class A)
%   - tab_AALC_controller_testset.tex: test set (NTM class A, new seed)
%   writeAALC_ControllerTableTex(figDir) writes into figDir (default
%   plotFunktionen/figIPCThesis).

plotDir = fileparts(mfilename('fullpath'));
if nargin < 1, figDir = fullfile(plotDir, 'figIPCThesis'); end
fadeIn = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'FadeIn');

sets = struct('file', {'AALC_ControllerTable', 'AALC_ControllerTable_TestSet'}, ...
    'tex', {'tab_AALC_controller_optset', 'tab_AALC_controller_testset'}, ...
    'label', {'tab:AALC_controller_optset', 'tab:AALC_controller_testset'}, ...
    'short', {'optimization set', 'test set'}, ...
    'long', {'the optimization wind set (NTM class A, the seeds used for the tuning)', ...
             'the test wind set (NTM class A, new seeds not used for the tuning)'});
for s = 1:numel(sets)
    T = load(fullfile(fadeIn, [sets(s).file '.mat']), 'Tab');
    writeTable(T.Tab, fullfile(figDir, [sets(s).tex '.tex']), sets(s));
end
end

function writeTable(Tab, fTex, set)
fid = fopen(fTex, 'w');
closeF = onCleanup(@() fclose(fid));
p = @(varargin) fprintf(fid, varargin{:});
p('%% Created by writeAALC_ControllerTableTex from makeAALC_ControllerTable on %s\n', datestr(now, 'yyyy-mm-dd')); %#ok<TNOW1,DATST>
p('%% AALC: IPC K_P, K_I and TEF K_P, pitch rate limit 8 deg/s, IPC/TEF fade-in; evaluation from 66 s\n');
p('%% Changes relative to the baseline (IPC and TEF off) on the same wind field; DEL Woehler exponent 8 (blade), 3 (tower)\n');
p('\\begin{table}[htbp]\n    \\centering\n');
p('    \\caption[AALC gains and changes over the wind speed (%s).]{AALC controller gains and relative changes to the\n', set.short);
p('        baseline over the mean wind speed for %s. Below rated, the gains were tuned at each\n', set.long);
p('        wind speed (fminsearch); from 10\\,m/s on, the gains tuned at 18\\,m/s (fmincon, tower DEL constraint) are used.\n');
p('        $\\Delta$DEL blade is the change of the worst of the three blade root out-of-plane DELs. The pitch activity\n');
p('        change $\\Delta$ADC is the change of the mean absolute pitch rate, given in \\textdegree/s since the baseline\n');
p('        pitch is constant at low wind speeds; where the baseline pitch is active, the relative change is given in brackets.');
hasOpt = any(contains(Tab.Source, "OPTIMIZATION"));
if hasOpt
    p('\n        $^\\dagger$The test set has no 11\\,m/s wind field; this row is simulated on the optimization set.');
end
p('}\n    \\label{%s}\n', set.label);
p('    \\begin{adjustbox}{max width=\\textwidth}\n    \\begin{tabular}{r rrr rrrr r}\n        \\toprule\n');
p('        & \\multicolumn{3}{c}{Gains} & \\multicolumn{4}{c}{Change to baseline (\\%%)} & \\\\\n');
p('        \\cmidrule(lr){2-4} \\cmidrule(lr){5-8}\n');
p('        $v$ (m/s) & IPC $K_P$ & IPC $K_I$ & TEF $K_P$ & DEL blade & DEL tower & Mean power & Std power & $\\Delta$ADC (\\textdegree/s) \\\\\n');
p('        \\midrule\n');
for k = 1:height(Tab)
    r = Tab(k, :);
    if k > 1 && Tab.WindSpeed_mps(k-1) < 10 && r.WindSpeed_mps >= 10
        p('        \\midrule\n');
    end
    ws = sprintf('%d', r.WindSpeed_mps);
    if contains(r.Source, "OPTIMIZATION"), ws = [ws '$^\dagger$']; end %#ok<AGROW>
    if isfinite(r.RelADC_pct)
        adc = sprintf('%.2f (%+.0f\\,\\%%)', r.DeltaADC_degps, r.RelADC_pct);
    else
        adc = sprintf('%.2f', r.DeltaADC_degps);
    end
    p('        %s & %.3f & %.3f & %.3f & %s & %s & %s & %s & %s \\\\\n', ws, r.IPC_K_P, r.IPC_K_I, r.TEF_K_P, ...
        pct(r.RelDEL_WorstBlade_pct), pct(r.RelDEL_Tower_pct), pct(r.RelMeanPower_pct), ...
        pct(r.RelStdPower_pct), adc);
end
p('        \\bottomrule\n    \\end{tabular}\n    \\end{adjustbox}\n\\end{table}\n');
end

function s = pct(x)
% Signed percentage with one decimal, "0.0" without sign for |x| < 0.05
if abs(x) < 0.05
    s = '0.0';
else
    s = sprintf('%+.1f', x);
end
end
