function Results = optimizeIPC_PI_RateLimits(opts)
%OPTIMIZEIPC_PI_RATELIMITS Optimize the PI-IPC gains for several pitch rate limits
%   Results = optimizeIPC_PI_RateLimits(opts) optimizes K_P and K_I of the
%   PI individual pitch controller with fminsearch for each pitch rate
%   limit in opts.RateLimits (deg/s). The TEF controller is inactive, the
%   baseline controllers (GenTq, CPC) are active. For every rate limit a
%   baseline simulation (IPC off) with the same rate limit is run first.
%   The optimization uses one wind field only (default: 18 m/s, NTM class
%   A, optimization set).
%
%   The cost function corresponds to CostFunctionDELAllMoments: the
%   largest relative change of the blade root DELs (RootMyc1..3, Woehler
%   exponent 8) compared to the baseline. The DELs are computed directly
%   from the Simulink output (rainflow, 1 Hz equivalent), so MCrunch and
%   Excel are not required.
%
%   With opts.Optimizer = "fmincon" (SQP, finite differences) the same cost
%   is minimized subject to the constraint that the relative change of the
%   tower base DEL (TwrBsMyt) is at most opts.TowerMaxRelDEL (default 0,
%   i.e. the tower load must not get worse than in the baseline).
%
%   opts.WindFile can be a string array of several wind files (seeds). Then
%   a baseline is simulated for every wind file and the cost of a gain set
%   is aggregated over the wind files (opts.SeedAggregation "max": worst
%   case, or "mean"). If a simulation fails on one wind file, the gain set
%   gets the penalty cost without simulating the remaining wind files.
%
%   The pitch rate limit is applied to the total blade pitch command
%   (CPC + IPC) in the pitch actuator model and to the rate saturation of
%   the CPC (Control.Pitch.Minrate/Maxrate). The model is changed in memory
%   only and is not saved.
%
%   opts.Vars selects the optimization variables x:
%   - "IPC" (default): [K_P, K_I] of the IPC, TEF off
%   - "TEF_KP": K_P of the TEF controller, IPC on with the fixed gains
%     opts.IPCGains = [K_P, K_I]
%   - "TEF_KPKD": [K_P, K_D/opts.TEFKDScale] of the TEF controller (K_D
%     scaled, default 0.01, so that both variables have a similar size), IPC
%     on with opts.IPCGains
%   - "IPC_TEF_KP": [K_P, K_I] of the IPC and K_P of the TEF controller
%     together (TEF K_D = 0)
%   The TEF K_I is opts.TEF_K_I (default 0). The baseline is always IPC and
%   TEF off, so the costs of all variants are comparable.
%
%   Start from the Main folder, e.g.
%       Results = optimizeIPC_PI_RateLimits;
%       Results = optimizeIPC_PI_RateLimits(struct('RateLimits',8,'TMax',100,'MaxFunEvals',2));

arguments
    opts struct = struct()
end

def.RateLimits    = [4 8 13];                                              % deg/s
def.WindFile      = fullfile("WindData","Eigene_Wind_Dateien","TurbKlasseA","18mps.bts");
def.TMax          = 660;                                                   % s
def.TStartLog     = 66;                                                    % s, start of evaluation window
def.x0            = [0.354, 1.194213];                                     % [K_P, K_I] start values
def.MaxFunEvals   = 60;
def.TolX          = 1e-2;
def.TolFun        = 1e-4;
def.SimulinkFile  = 'ClosedLoop_V5_2020b.slx';
def.ResultsFolder = '';
def.WorkFolder    = '';                                                    % private copy of FAST_Sim_TEF for parallel runs
def.Optimizer     = "fminsearch";                                          % "fminsearch", "fmincon" or "none" (evaluate rows of x0)
def.lb            = [0 0];                                                 % fmincon bounds for [K_P, K_I]
def.ub            = [2 2];
def.TowerMaxRelDEL = 0;                                                    % fmincon: max. relative change of DEL TwrBsMyt
def.FiniteDiffStep = 1e-2;                                                 % fmincon: finite difference step (relative)
def.SaveTimeSeries = false;                                                % save OutData of baseline and optimum
def.InitialStep   = [];                                                   % fminsearch: size of the initial simplex in gain units (default: 5 % of x0)
def.SeedAggregation = "max";                                               % several wind files: "max" or "mean" of the costs
def.Vars          = "IPC";                                                  % "IPC", "TEF_KP", "TEF_KPKD" or "IPC_TEF_KP"
def.IPCGains      = [1.0959 0.2504];                                        % fixed IPC [K_P, K_I] for the TEF variants
def.TEF_K_I       = 0;                                                      % TEF K_I (not optimized)
def.TEFKDScale    = 0.01;                                                   % TEF_KPKD: K_D = x(2)*TEFKDScale
fn = fieldnames(def);
for k = 1:numel(fn)
    if ~isfield(opts, fn{k}), opts.(fn{k}) = def.(fn{k}); end
end

%% Paths and input files
opts.WindFile = string(opts.WindFile);                                    % Edit_InflowWind_V2 needs a string
mainFolderPath = pwd;
[~, name] = fileparts(mainFolderPath);
if name ~= "Main"
    error('Start optimizeIPC_PI_RateLimits from the Main folder.');
end
programmFolderPath = fullfile(fileparts(mainFolderPath), 'FAST_Sim_TEF');
if ~isempty(opts.WorkFolder)
    % Private copy of the FAST/Simulink files (without the wind data except
    % the selected file), so that several optimizations can run in parallel
    workFolderPath = prepareWorkCopy(programmFolderPath, opts.WorkFolder, opts.WindFile(1));
    for s = 2:numel(opts.WindFile)
        prepareWorkCopy(programmFolderPath, opts.WorkFolder, opts.WindFile(s));
    end
    programmFolderPath = workFolderPath;
    Simulink.fileGenControl('set', 'CacheFolder', opts.WorkFolder, ...
        'CodeGenFolder', opts.WorkFolder, 'createDir', true);
end
addpath(fullfile(mainFolderPath, 'funktionen'));
addpath(genpath(programmFolderPath));

inputFolderPath    = fullfile(programmFolderPath, '5MW-Turbine-Inputfiles');
FAST_InputFileName = fullfile(inputFolderPath, '5MW_Land.fst');
InflowWindFilePath = fullfile(inputFolderPath, 'Sub-Inputfiles', 'NRELOffshrBsline5MW_InflowWind_12mps.dat');
SimulinkFilePath   = fullfile(programmFolderPath, 'simulink', opts.SimulinkFile);
[~, mdl] = fileparts(SimulinkFilePath);

nSeeds = numel(opts.WindFile);
for s = 1:nSeeds
    if ~isfile(fullfile(inputFolderPath, 'Sub-Inputfiles', opts.WindFile(s)))
        error('Wind file %s does not exist.', opts.WindFile(s));
    end
end
Edit_fst(FAST_InputFileName, floor(opts.TStartLog));
setWindFile(InflowWindFilePath, opts.WindFile(1));

if isempty(opts.ResultsFolder)
    opts.ResultsFolder = fullfile(mainFolderPath, 'Post_processing', ...
        ['IPC_PI_RateLimitOpt_' datestr(now, 'yyyymmdd_HHMM')]); %#ok<TNOW1,DATST>
end
if ~exist(opts.ResultsFolder, 'dir'), mkdir(opts.ResultsFolder); end
diary(fullfile(opts.ResultsFolder, 'Log.txt'));
cleanupObj = onCleanup(@() diary('off'));

%% Simulation configuration (TEF off)
SimConfig.TMax               = opts.TMax;
SimConfig.FAST_InputFileName = FAST_InputFileName;
SimConfig.controller.GenTq.GenTq_Cotroller_switch = 1;
SimConfig.controller.CPC.CPC_Cotroller_switch     = 1;
SimConfig.controller.CPC.InitialPitchAngle        = 20;
SimConfig.controller.TEF.TEF_Cotroller_switch     = 0;
SimConfig.controller.TEF.TEF_OLvalue              = 0;
SimConfig.controller.TEF.K_P = 0;
SimConfig.controller.TEF.K_I = 0;
SimConfig.controller.TEF.K_D = 0;
SimConfig.controller.TEF.G   = 0;
SimConfig.controller.IPC.K_D = 0;

assignin('base', 'TMax', opts.TMax);
assignin('base', 'DT', 0.01);
assignin('base', 'FAST_InputFileName', FAST_InputFileName);
LoadDataForCPC(SimConfig);
ControlDefault = evalin('base', 'Control');

load_system(SimulinkFilePath);
closeMdl = onCleanup(@() close_system(mdl, 0));
actuators = {'Aktuatormodel für den Pitchaktuator1', 'Aktuatormodel für den Pitchaktuator2'};

%% Loop over rate limits
Results = struct([]);
for r = 1:numel(opts.RateLimits)
    rl = opts.RateLimits(r);
    fprintf('\n=============================================================\n');
    fprintf('Pitch rate limit %g deg/s\n', rl);
    fprintf('=============================================================\n');

    % Rate limit for the CPC rate saturation and the pitch actuator
    Control = ControlDefault;
    Control.Pitch.Maxrate =  rl;
    Control.Pitch.Minrate = -rl;
    assignin('base', 'Control', Control);
    for a = 1:numel(actuators)
        set_param([mdl '/' actuators{a} '/Constant2'], 'Value', 'Control.Pitch.Maxrate*pi/180');
        set_param([mdl '/' actuators{a} '/Constant3'], 'Value', 'Control.Pitch.Minrate*pi/180');
    end

    % Baseline: IPC off, for every wind file
    base = cell(1, nSeeds);
    for s = 1:nSeeds
        setWindFile(InflowWindFilePath, opts.WindFile(s));
        base{s} = simulateIPC(mdl, SimConfig, struct('ipcOn', 0, 'ipc', [0 0], 'tefOn', 0, 'tef', [0 0 0]), opts);
        if ~base{s}.ok
            error('Baseline simulation failed for rate limit %g deg/s, wind file %s: %s', ...
                rl, opts.WindFile(s), base{s}.msg);
        end
        fprintf('Baseline %s: DEL RootMyc = [%.0f %.0f %.0f] kNm, DEL TwrBsMyt = %.0f kNm\n', ...
            opts.WindFile(s), base{s}.DEL.RootMyc, base{s}.DEL.TwrBsMyt);
    end

    % Optimization of [K_P, K_I]
    History = table();
    cache = containers.Map('KeyType', 'char', 'ValueType', 'any');        % fmincon evaluates cost and constraint separately
    fun = @(x) costIPC(x);
    switch opts.Optimizer
        case "fminsearch"
            if isempty(opts.InitialStep)
                fsOpts = optimset('Display', 'iter', 'MaxFunEvals', opts.MaxFunEvals, ...
                    'TolX', opts.TolX, 'TolFun', opts.TolFun);
                [xOpt, Jopt, exitflag, output] = fminsearch(fun, opts.x0, fsOpts);
            else
                % fminsearch starts with steps of 5 % of z0 = 1, so x = x0 + (z - 1).*scale
                % gives initial steps of opts.InitialStep
                scale = opts.InitialStep / 0.05;
                fsOpts = optimset('Display', 'iter', 'MaxFunEvals', opts.MaxFunEvals, ...
                    'TolX', opts.TolX / max(scale), 'TolFun', opts.TolFun);
                [zOpt, Jopt, exitflag, output] = fminsearch(@(z) fun(opts.x0 + (z - 1).*scale), ...
                    ones(size(opts.x0)), fsOpts);
                xOpt = opts.x0 + (zOpt - 1).*scale;
            end
        case "fmincon"
            % Blade root DEL as cost, the tower DEL must not get worse
            fcOpts = optimoptions('fmincon', 'Algorithm', 'sqp', 'Display', 'iter', ...
                'MaxFunctionEvaluations', opts.MaxFunEvals, 'StepTolerance', opts.TolX, ...
                'OptimalityTolerance', opts.TolFun, 'ConstraintTolerance', 1e-3, ...
                'FiniteDifferenceStepSize', opts.FiniteDiffStep);
            [xOpt, Jopt, exitflag, output] = fmincon(fun, opts.x0, [], [], [], [], ...
                opts.lb, opts.ub, @towerConstraint, fcOpts);
        case "none"
            % Only evaluate the gain sets in the rows of x0 (e.g. on other wind seeds)
            J = arrayfun(@(k) costIPC(opts.x0(k,:)), 1:size(opts.x0, 1));
            [Jopt, kBest] = min(J);
            xOpt = opts.x0(kBest,:);
            exitflag = 0;
            output = struct('funcCount', numel(J));
        otherwise
            error('Unknown optimizer "%s".', opts.Optimizer);
    end

    % Re-simulate the optimum on every wind file to store its metrics
    best = cell(1, nSeeds);
    relS = cell(1, nSeeds);
    for s = 1:nSeeds
        setWindFile(InflowWindFilePath, opts.WindFile(s));
        best{s} = simulateIPC(mdl, SimConfig, gainsFromX(xOpt, opts), opts);
        if ~best{s}.ok
            error('Re-simulation of the optimum failed for wind file %s: %s', opts.WindFile(s), best{s}.msg);
        end
        relS{s} = relativeChange(best{s}, base{s});
    end
    if opts.SaveTimeSeries
        TimeSeries = struct('WindFile', opts.WindFile, ...
            'Baseline', {cellfun(@(b) b.TS, base, 'UniformOutput', false)}, ...
            'Optimum', {cellfun(@(b) b.TS, best, 'UniformOutput', false)});
        if nSeeds == 1
            TimeSeries.Baseline = TimeSeries.Baseline{1};
            TimeSeries.Optimum  = TimeSeries.Optimum{1};
        end
        save(fullfile(opts.ResultsFolder, sprintf('TimeSeries_RL%02d.mat', rl)), 'TimeSeries');
        base = cellfun(@(b) rmfield(b, 'TS'), base, 'UniformOutput', false);
        best = cellfun(@(b) rmfield(b, 'TS'), best, 'UniformOutput', false);
    end
    rel = aggregateRel(relS);
    base = cellfun(@(b) rmfield(b, 'ok'), base, 'UniformOutput', false);
    best = cellfun(@(b) rmfield(b, 'ok'), best, 'UniformOutput', false);

    Results(r).RateLimit = rl;
    Results(r).Optimizer = opts.Optimizer;
    gOpt = gainsFromX(xOpt, opts);
    Results(r).K_P       = gOpt.ipc(1);
    Results(r).K_I       = gOpt.ipc(2);
    Results(r).TEF_K_P   = gOpt.tef(1);
    Results(r).TEF_K_I   = gOpt.tef(2);
    Results(r).TEF_K_D   = gOpt.tef(3);
    Results(r).Vars      = opts.Vars;
    Results(r).Cost      = Jopt;
    Results(r).ExitFlag  = exitflag;
    Results(r).Output    = output;
    Results(r).WindFile  = opts.WindFile;
    if nSeeds == 1
        Results(r).Baseline = base{1};
        Results(r).Optimum  = best{1};
    else
        Results(r).Baseline = base;
        Results(r).Optimum  = best;
    end
    Results(r).RelChange = rel;                                            % worst case (DEL) / mean (ADC, power) over the wind files
    Results(r).RelChangeSeeds = relS;
    Results(r).History   = History;

    writetable(History, fullfile(opts.ResultsFolder, sprintf('History_RL%02d.csv', rl)));
    save(fullfile(opts.ResultsFolder, 'Results.mat'), 'Results', 'opts');

    fprintf('\nRate limit %g deg/s: K_P = %.6f, K_I = %.6f, TEF K_P = %.6f, K_I = %.6f, K_D = %.6f, cost = %.4f (%d evaluations)\n', ...
        rl, gOpt.ipc(1), gOpt.ipc(2), gOpt.tef(1), gOpt.tef(2), gOpt.tef(3), Jopt, output.funcCount);
    fprintf('  DEL RootMyc1..3: %+.1f %+.1f %+.1f %%, DEL TwrBsMyt: %+.1f %%, pitch ADC: %+.1f %%, power: %+.2f %%\n', ...
        100*rel.RootMyc, 100*rel.TwrBsMyt, 100*rel.ADC, 100*rel.Power);
end

% Summary table
Summary = table([Results.RateLimit]', [Results.K_P]', [Results.K_I]', ...
    [Results.TEF_K_P]', [Results.TEF_K_I]', [Results.TEF_K_D]', [Results.Cost]', ...
    arrayfun(@(s) 100*s.RelChange.TwrBsMyt, Results)', arrayfun(@(s) 100*s.RelChange.ADC, Results)', ...
    arrayfun(@(s) 100*s.RelChange.Power, Results)', ...
    'VariableNames', {'RateLimit_degps', 'K_P', 'K_I', 'TEF_K_P', 'TEF_K_I', 'TEF_K_D', 'Cost_maxRelDEL_RootMyc', ...
    'RelDEL_TwrBsMyt_pct', 'RelADC_pct', 'RelPower_pct'});
disp(Summary);
writetable(Summary, fullfile(opts.ResultsFolder, 'Summary.csv'));
save(fullfile(opts.ResultsFolder, 'Results.mat'), 'Results', 'Summary', 'opts');

    function J = costIPC(x)
        [J, ~] = evaluateIPC(x);
    end

    function [c, ceq] = towerConstraint(x)
        [~, relx] = evaluateIPC(x);
        if isnan(relx.TwrBsMyt)
            c = 1;                                                         % failed run counts as infeasible
        else
            c = relx.TwrBsMyt - opts.TowerMaxRelDEL;
        end
        ceq = [];
    end

    function [J, relx] = evaluateIPC(x)
        key = sprintf('%.15g,', x);
        if isKey(cache, key)
            v = cache(key);
            J = v{1};
            relx = v{2};
            return;
        end
        Js   = nan(1, nSeeds);
        relSd = repmat({struct('RootMyc', nan(1,3), 'TwrBsMyt', NaN, 'ADC', NaN, 'Power', NaN)}, 1, nSeeds);
        for sd = 1:nSeeds
            if nSeeds > 1, setWindFile(InflowWindFilePath, opts.WindFile(sd)); end
            res = simulateIPC(mdl, SimConfig, gainsFromX(x, opts), opts);
            if ~res.ok
                Js(sd) = 1;                                                % penalty for failed or unstable runs
                break;                                                     % remaining wind files are not needed
            end
            relSd{sd} = relativeChange(res, base{sd});
            Js(sd) = max(relSd{sd}.RootMyc);                               % as CostFunctionDELAllMoments (without /100 for %)
        end
        if any(Js == 1) || nSeeds == 1 || opts.SeedAggregation == "max"
            J = max(Js);
        else
            J = mean(Js);
        end
        relx = aggregateRel(relSd);
        g = gainsFromX(x, opts);
        row = table(datetime('now'), g.ipc(1), g.ipc(2), J, ...
            relx.RootMyc(1), relx.RootMyc(2), relx.RootMyc(3), relx.TwrBsMyt, relx.ADC, relx.Power, ...
            'VariableNames', {'Time', 'K_P', 'K_I', 'Cost', 'RelDEL_RootMyc1', 'RelDEL_RootMyc2', ...
            'RelDEL_RootMyc3', 'RelDEL_TwrBsMyt', 'RelADC', 'RelPower'});
        if g.tefOn
            row.TEF_K_P = g.tef(1);
            row.TEF_K_I = g.tef(2);
            row.TEF_K_D = g.tef(3);
        end
        if nSeeds > 1
            for sd = 1:nSeeds
                row.(sprintf('Cost_seed%d', sd)) = Js(sd);
                row.(sprintf('RelDEL_TwrBsMyt_seed%d', sd)) = relSd{sd}.TwrBsMyt;
            end
        end
        History = [History; row];
        fprintf('  K_P = %9.5f, K_I = %9.5f', g.ipc(1), g.ipc(2));
        if g.tefOn, fprintf(', TEF K_P = %9.5f, K_D = %9.6f', g.tef(1), g.tef(3)); end
        fprintf(' -> J = %+.5f, tower %+.2f %%', J, 100*relx.TwrBsMyt);
        if nSeeds > 1, fprintf(' (seeds: %s)', sprintf('%+.4f ', Js)); end
        fprintf('\n');
        cache(key) = {J, relx};
    end
end

function g = gainsFromX(x, opts)
% Controller gains of the optimization variables x (see opts.Vars)
switch opts.Vars
    case "IPC"
        g = struct('ipcOn', 1, 'ipc', x(1:2), 'tefOn', 0, 'tef', [0 0 0]);
    case "TEF_KP"
        g = struct('ipcOn', 1, 'ipc', opts.IPCGains, 'tefOn', 1, 'tef', [x(1), opts.TEF_K_I, 0]);
    case "TEF_KPKD"
        g = struct('ipcOn', 1, 'ipc', opts.IPCGains, 'tefOn', 1, ...
            'tef', [x(1), opts.TEF_K_I, x(2)*opts.TEFKDScale]);
    case "IPC_TEF_KP"
        g = struct('ipcOn', 1, 'ipc', x(1:2), 'tefOn', 1, 'tef', [x(3), opts.TEF_K_I, 0]);
    otherwise
        error('Unknown opts.Vars "%s".', opts.Vars);
end
end

function res = simulateIPC(mdl, SimConfig, g, opts)
% Run one closed-loop simulation with the gains g (gainsFromX) and evaluate
% loads, pitch activity and power
SimConfig.controller.IPC.IPC_Cotroller_switch = g.ipcOn;
SimConfig.controller.IPC.K_P = g.ipc(1);
SimConfig.controller.IPC.K_I = g.ipc(2);
SimConfig.controller.TEF.TEF_Cotroller_switch = g.tefOn;
SimConfig.controller.TEF.K_P = g.tef(1);
SimConfig.controller.TEF.K_I = g.tef(2);
SimConfig.controller.TEF.K_D = g.tef(3);
assignin('base', 'SimConfig', SimConfig);

res.ok  = false;
res.msg = '';
try
    clear mex                                                              % avoid FAST crash on restart ('memory already allocated')
    out = sim(mdl, 'StopTime', num2str(opts.TMax), 'ReturnWorkspaceOutputs', 'on');
    clear mex
    OutData = out.get('OutData');
    OutList = string(evalin('base', 'OutList'));
catch ME
    clear mex
    res.msg = ME.message;
    for c = 1:numel(ME.cause)
        res.msg = sprintf('%s\n  %s', res.msg, ME.cause{c}.message);
    end
    warning('IPCopt:simFailed', 'Simulation failed: %s', res.msg);
    return;
end

ch  = @(name) OutData(:, find(strtrim(OutList) == name, 1));
t   = ch("Time");
idx = t >= opts.TStartLog;
T   = t(find(idx, 1, 'last')) - t(find(idx, 1));
if isempty(T) || T < 0.9*(opts.TMax - opts.TStartLog) || any(~isfinite(OutData(idx, :)), 'all')
    res.msg = 'incomplete or non-finite output';
    return;
end

for b = 1:3
    res.DEL.RootMyc(b) = del(ch("RootMyc" + b), idx, 8, T);
end
res.DEL.TwrBsMyt = del(ch("TwrBsMyt"), idx, 3, T);

dt = mean(diff(t(idx)));
pitchRate = zeros(nnz(idx) - 1, 3);
for b = 1:3
    pitch = ch("BldPitch" + b);
    pitchRate(:, b) = diff(pitch(idx)) / dt;                               % deg/s
end
res.ADC      = mean(abs(pitchRate), 'all');                                % mean absolute pitch rate (deg/s)
res.MaxRate  = max(abs(pitchRate), [], 'all');
power        = ch("GenPwr");
genSpeed     = ch("GenSpeed");
res.Power    = mean(power(idx));                                           % kW
res.StdSpeed = std(genSpeed(idx));                                         % rpm
res.x        = g;
if opts.SaveTimeSeries
    res.TS = struct('OutData', OutData, 'OutList', OutList);
end
res.ok       = true;
end

function workProgrammFolder = prepareWorkCopy(programmFolderPath, workFolder, windFile)
% Copy FAST_Sim_TEF to workFolder without the wind data, except windFile
workProgrammFolder = fullfile(workFolder, 'FAST_Sim_TEF');
windRel = fullfile('5MW-Turbine-Inputfiles', 'Sub-Inputfiles', 'WindData');
if ~exist(workProgrammFolder, 'dir')
    mkdir(workProgrammFolder);
    items = dir(programmFolderPath);
    items = items(~ismember({items.name}, {'.', '..'}));
    for k = 1:numel(items)
        if items(k).name ~= "5MW-Turbine-Inputfiles"
            copyfile(fullfile(programmFolderPath, items(k).name), fullfile(workProgrammFolder, items(k).name));
        end
    end
    src = fullfile(programmFolderPath, '5MW-Turbine-Inputfiles');
    dst = fullfile(workProgrammFolder, '5MW-Turbine-Inputfiles');
    mkdir(dst);
    items = dir(src);
    items = items(~[items.isdir]);
    for k = 1:numel(items)
        copyfile(fullfile(src, items(k).name), dst);
    end
    subSrc = fullfile(src, 'Sub-Inputfiles');
    subDst = fullfile(dst, 'Sub-Inputfiles');
    mkdir(subDst);
    items = dir(subSrc);
    items = items(~ismember({items.name}, {'.', '..', 'WindData'}));
    for k = 1:numel(items)
        copyfile(fullfile(subSrc, items(k).name), fullfile(subDst, items(k).name));
    end
end
windDst = fullfile(fileparts(fullfile(workProgrammFolder, windRel)), windFile);
if ~isfile(windDst)
    mkdir(fileparts(windDst));
    copyfile(fullfile(programmFolderPath, '5MW-Turbine-Inputfiles', 'Sub-Inputfiles', windFile), windDst);
end
end

function rel = aggregateRel(relS)
% Worst case of the DEL changes and mean of ADC and power over the wind files
% (NaN if a wind file was not simulated or failed)
R = [relS{:}];
rel.RootMyc  = max(vertcat(R.RootMyc), [], 1, 'includenan');
rel.TwrBsMyt = max([R.TwrBsMyt], [], 'includenan');
rel.ADC      = mean([R.ADC]);
rel.Power    = mean([R.Power]);
end

function setWindFile(inflowWindFilePath, windFile)
% Set the full field wind file (line 21 of the InflowWind input file)
lines = readlines(inflowWindFilePath);
lines(21) = '"' + windFile + '"     FileName_BTS   - Name of the Full field wind file to use (.bts)';
if lines(end) == "", lines(end) = []; end                                  % writelines adds the final newline
writelines(lines, inflowWindFilePath);
end

function D = del(y, idx, m, T)
% Damage equivalent load with 1 Hz equivalent frequency (half cycles count 0.5)
c = rainflow(y(idx));
D = (sum(c(:, 1) .* c(:, 2).^m) / T)^(1/m);
end

function rel = relativeChange(res, base)
rel.RootMyc  = res.DEL.RootMyc ./ base.DEL.RootMyc - 1;
rel.TwrBsMyt = res.DEL.TwrBsMyt / base.DEL.TwrBsMyt - 1;
rel.ADC      = res.ADC / base.ADC - 1;
rel.Power    = res.Power / base.Power - 1;
end
