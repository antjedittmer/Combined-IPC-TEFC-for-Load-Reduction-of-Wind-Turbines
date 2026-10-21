function files = storeIPC_FadeInTimeSeries(runs)
%STOREIPC_FADEINTIMESERIES Time series of the fmincon gains with the fade-in
%   files = storeIPC_FadeInTimeSeries simulates, one after another, the
%   baseline and the fmincon optimum of the re-optimization with the IPC/TEF
%   fade-in (Results_IPC_PI_RateLimitOpt/FadeIn) and stores the time series
%   in Main/Post_processing/IPCfade_TS_<run>/TimeSeries_RLxx.mat (git-ignored)
%   and, reduced to 25 channels, in
%   Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries/TimeSeries_<run>.mat
%   (files, committed; plot these without simulating):
%   - RL04:        IPC K_P = 0.2533, K_I = 0.1033, 4 deg/s
%   - RL08:        IPC K_P = 1.2219, K_I = 0.3702, 8 deg/s
%   - RL13:        IPC K_P = 1.2227, K_I = 0.3653, 13 deg/s
%   - RL08_IPCTEF: IPC K_P = 0.0820, K_I = 0.6694, TEF K_P = 0.6411, 8 deg/s
%   files = storeIPC_FadeInTimeSeries(["RL04" "RL08"]) runs only these.
%   Each run takes about 3 min (two 660 s simulations). Start from the
%   Main folder. Plot with plotFunktionen/plotIPC_PSD_RateLimits.

arguments
    runs string = ["RL04" "RL08" "RL13" "RL08_IPCTEF"]
end

B = load(fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'best.mat'), 'best');
cfg = {
    "RL04",        4,  "IPC",        B.best.RL04_IPC_fmincon
    "RL08",        8,  "IPC",        B.best.RL08_IPC_fmincon
    "RL13",        13, "IPC",        B.best.RL13_IPC_fmincon
    "RL08_IPCTEF", 8,  "IPC_TEF_KP", B.best.RL08_IPC_TEF_KP_fmincon
    };
files = strings(1, numel(runs));
for k = 1:numel(runs)
    c = find([cfg{:,1}] == runs(k));
    if isempty(c), error('Unknown run "%s".', runs(k)); end
    folder = fullfile(pwd, 'Post_processing', char("IPCfade_TS_" + runs(k)));
    fprintf('\n##### %s: rate limit %d deg/s, %s, x = %s\n', runs(k), cfg{c,2}, cfg{c,3}, mat2str(cfg{c,4}, 5));
    optimizeIPC_PI_RateLimits(struct('RateLimits', cfg{c,2}, 'Vars', cfg{c,3}, ...
        'Optimizer', "none", 'x0', cfg{c,4}, 'SaveTimeSeries', true, 'ResultsFolder', folder));
    % Reduced copy (25 channels) for the repository
    files(k) = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries', ...
        char("TimeSeries_" + runs(k) + ".mat"));
    reduceTimeSeries(fullfile(folder, sprintf('TimeSeries_RL%02d.mat', cfg{c,2})), files(k));
end
end
