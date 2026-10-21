function plotAALC_PSD_comparison(figDir)
%PLOTAALC_PSD_COMPARISON AALC PSD comparison as plotPaper02_PSD_comparison
%   plotAALC_PSD_comparison plots the two PSD figures of the paper
%   (plotPaper02_PSD_comparison, 16 m/s) for the wind field of the IPC
%   tuning (18 m/s, NTM class A, optimization set, IPC/TEF fade-in, 8 deg/s)
%   from the precomputed PSDs (storeAALC_PSD, PSD_RL08_AALC.mat):
%   - fig02_PSDroot_breaky_AALCinit: baseline, IPC K_I = 1, TEFC K_P = 1
%   - fig02_PSDroot_breaky1c_AALC:   baseline, AALC (IPC K_I = 1 and
%     TEFC K_P = 1), AALC opt. (fmincon, IPC K_P, K_I and TEFC K_P)
%   plotAALC_PSD_comparison(figDir) saves png and eps in figDir (default
%   plotFunktionen/figIPCThesis).

plotDir = fileparts(mfilename('fullpath'));
if nargin < 1, figDir = fullfile(plotDir, 'figIPCThesis'); end
ts = fullfile(fileparts(plotDir), 'Results_IPC_PI_RateLimitOpt', 'FadeIn', 'TimeSeries');
plotIPC_PSD_Paper(struct('PSDFile', fullfile(ts, 'PSD_RL08_AALC.mat'), ...
    'Labels', ["IPC", "TEFC", "AALC", "IPC opt.", "AALC opt."], ...
    'Groups', {{[1 2], [3 5]}}, 'StyleIdx', [1 2 3 1 4], 'FigDir', figDir, ...
    'FigNames', ["fig02_PSDroot_breaky_AALCinit", "fig02_PSDroot_breaky1c_AALC"]));
end
