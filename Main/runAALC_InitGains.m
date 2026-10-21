function runAALC_InitGains()
%RUNAALC_INITGAINS IPC K_I = 1, TEF K_P = 1 and both, at 18 m/s (IPC wind set)
%   runAALC_InitGains simulates, as in the paper (SimInitCtrl_P1_I1,
%   plotPaper02_PSD_comparison), the initial gains on the wind field used
%   for the IPC tuning (18 m/s, NTM class A, optimization set) with the
%   IPC/TEF fade-in and the default pitch rate limit of 8 deg/s:
%     IPC_I1        IPC K_I = 1, all other IPC and TEF gains 0
%     TEF_P1        TEF K_P = 1, all other IPC and TEF gains 0
%     IPC_I1_TEF_P1 IPC K_I = 1 and TEF K_P = 1 (AALC), all other gains 0
%   Every run also simulates the baseline (IPC and TEF off). The full
%   results are written to Main/Post_processing/AALC_InitGains/<case>
%   (git-ignored), the reduced time series to
%   Results_IPC_PI_RateLimitOpt/FadeIn/TimeSeries/TimeSeries_RL08_<case>.mat.
%   Runs that already have a Results.mat are skipped. Start from the Main folder.

cases = { ...
    "IPC_I1",        "IPC",        [0 1];
    "TEF_P1",        "IPC_TEF_KP", [0 0 1];
    "IPC_I1_TEF_P1", "IPC_TEF_KP", [0 1 1]};
simDir = fullfile(pwd, 'Post_processing', 'AALC_InitGains');
tsDir  = fullfile(pwd, 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
for c = 1:size(cases, 1)
    folder = fullfile(simDir, char(cases{c, 1}));
    if ~isfile(fullfile(folder, 'Results.mat'))
        fprintf('\n##### %s\n', cases{c, 1});
        optimizeIPC_PI_RateLimits(struct('RateLimits', 8, 'Optimizer', "none", ...
            'Vars', cases{c, 2}, 'x0', cases{c, 3}, 'SaveTimeSeries', true, 'ResultsFolder', folder));
    end
    reduceTimeSeries(fullfile(folder, 'TimeSeries_RL08.mat'), ...
        fullfile(tsDir, "TimeSeries_RL08_" + cases{c, 1} + ".mat"));
end
end
