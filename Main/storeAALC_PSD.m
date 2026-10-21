function P = storeAALC_PSD()
%STOREAALC_PSD PSDs of the AALC initial-gain runs for fast plotting
%   P = storeAALC_PSD computes the PSDs (plotIPC_PSD_RateLimits, Welch,
%   Hann 2^14, from 66 s) of the baseline and of the runs at 18 m/s with
%   the IPC wind set (8 deg/s, fade-in) and stores them, together with the
%   standard deviations and the DELs relative to the baseline, in
%   Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries/PSD_RL08_AALC.mat
%   (a few MB, so plots do not need the time series):
%     IPC_I1          IPC K_I = 1 (runAALC_InitGains)
%     TEF_P1          TEF K_P = 1
%     IPC_I1_TEF_P1   IPC K_I = 1 and TEF K_P = 1
%     RL08            IPC optimized (fmincon, fade-in)
%     RL08_IPCTEF     IPC and TEF K_P optimized (fmincon, fade-in)
%   P.f, P.f1P, P.Baseline.<channel> and P.Runs{k}.<channel> hold the
%   frequencies and PSDs, P.Labels and P.Files the runs, P.Std the standard
%   deviations (rows: baseline and runs) and P.RelDEL the DEL changes.
%   Start from the Main folder after runAALC_InitGains.

tsDir = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
suffix = ["_IPC_I1", "_TEF_P1", "_IPC_I1_TEF_P1", "", "_IPCTEF"];
labels = ["IPC K_I = 1", "TEFC K_P = 1", "AALC: IPC K_I = 1, TEFC K_P = 1", ...
          "IPC opt.", "AALC opt."];
files = fullfile(tsDir, "TimeSeries_RL08" + suffix + ".mat");
channels = ["RootMyc1", "RootMyc2", "RootMyc3", "TwrBsMyt", "TwrBsMxt", "YawBrMyp", ...
            "NcIMUTAxs", "BldPitch1", "GenPwr", "RotSpeed"];
Q = plotIPC_PSD_RateLimits(struct('Files', files, 'RateLimits', 8*ones(1, numel(files)), ...
    'Labels', labels, 'Channels', channels, 'BaselineRate', 8, 'Plot', false));

P = struct('f', Q.f, 'f1P', Q.f1P, 'Channels', channels, 'Labels', labels, ...
    'Files', files, 'Baseline', Q.Baseline, 'Runs', {Q.IPC}, 'TStart', 66);

% Standard deviations and DELs relative to the baseline of the first file
S = load(files(1), 'TimeSeries');
B = toTable(S.TimeSeries.Baseline);
sdCh = ["NcIMUTAxs", "GenPwr", "RotSpeed", "PitchRate1", "RootMyc1", "TwrBsMyt"];
sd = nan(numel(files) + 1, numel(sdCh));
del = nan(numel(files) + 1, 4);
for k = 0:numel(files)
    if k == 0
        T = B;
    else
        S = load(files(k), 'TimeSeries');
        T = toTable(S.TimeSeries.Optimum);
    end
    idx = T.Time >= P.TStart;
    T.PitchRate1 = [0; diff(T.BldPitch1) ./ diff(T.Time)];
    for c = 1:numel(sdCh)
        sd(k + 1, c) = std(T.(sdCh(c))(idx));
    end
    tEval = T.Time(find(idx, 1, 'last')) - T.Time(find(idx, 1));
    for b = 1:3
        del(k + 1, b) = delOf(T.("RootMyc" + b)(idx), 8, tEval);
    end
    del(k + 1, 4) = delOf(T.TwrBsMyt(idx), 3, tEval);
end
rowNames = ["Baseline", labels];
P.Std = array2table(sd, 'VariableNames', cellstr(sdCh), 'RowNames', cellstr(rowNames));
P.RelDEL = array2table(del(2:end, :) ./ del(1, :) - 1, ...
    'VariableNames', {'RootMyc1', 'RootMyc2', 'RootMyc3', 'TwrBsMyt'}, 'RowNames', cellstr(labels));
save(fullfile(tsDir, 'PSD_RL08_AALC.mat'), 'P', '-v7');
disp(P.Std); disp(P.RelDEL);
fprintf('PSDs saved to %s\n', fullfile(tsDir, 'PSD_RL08_AALC.mat'));
end

function T = toTable(TS)
T = array2table(TS.OutData, 'VariableNames', cellstr(TS.OutList(:))');
end

function d = delOf(x, m, T)
% 1 Hz damage equivalent load (rainflow), as in optimizeIPC_PI_RateLimits
c = rainflow(x);
d = (sum(c(:, 1) .* c(:, 2).^m) / T)^(1/m);
end
